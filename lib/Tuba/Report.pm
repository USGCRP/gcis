=head1 NAME

Tuba::Report : Controller class for reports.

=cut

package Tuba::Report;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use Pg::hstore qw/hstore_decode/;
use Encode;
use Tuba::Log;

sub _user_can_view {
    my $c = shift;
    my $report = shift or return;
    return 1 if $report->_public;
    my $user = $c->user or return 0;
    return 1 if $c->config->{authz}{root}{$user};
    return 1 if ReportViewer->new(username => $user, report => $report->identifier)->load(speculative => 1);
    return 0;
}

sub _user_can_edit {
    my $c = shift;
    my $report = shift or return;
    my $user = $c->user or return;
    return 1 if $c->config->{authz}{root}{$user};
    return 1 if ReportEditor->new(username => $user, report => $report->identifier)->load(speculative => 1);
    return 0;
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('report_identifier');
    my $object = Report->new( identifier => $identifier )
      ->load( speculative => 1, with => [qw/chapters/] )
      or return $c->render_not_found;
    return $c->render(status => 403, text => '403 Forbidden') unless $c->_user_can_view($object);
    $c->stash(object => $object);
    $c->stash(sorters => {
            figures => sub($$) { no warnings; $_[0]->stringify <=> $_[1]->stringify },
            findings => sub($$) { no warnings; $_[0]->stringify <=> $_[1]->stringify },
            tables => sub($$) { no warnings; $_[0]->stringify <=> $_[1]->stringify },
        }
    );
    $c->SUPER::show(@_);
}

sub _favorite_page {
    my $c = shift;
    my $user = $c->user;
    return
        int(
            Reports->get_objects_count(
            with_objects => [qw/_report_viewers/],
            query => [
                 and => [
                     or => [ and => [_public => 't'], and => [username => $user] ],
                     or => [ 'identifier' => { 'le' => 'nca3' } ],
                ]
            ]
        ) / 20 ) + 1;
}

sub list {
    my $c = shift;
    my $user = $c->user;

    my %query;
    if ($_ = $c->param('report_type')) {
        $query{report_type_identifier} = $_
    }
    if ($_ = $c->param('publication_year')) {
        $query{publication_year} = $_ if /^[0-9]{4}$/;
    }

    my $objects = Reports->get_objects(
        query => [
            %query,
            or => [ and => [_public => 't'],
                    and => [username => $user]
                  ]
        ],
        with_objects => [qw/_report_viewers/],
        ($c->param('all')
          ? ()
          : (page => $c->page, per_page => $c->per_page)),
        sort_by => 'identifier',
    );
    my $count = Reports->get_objects_count(
        query => [
            %query,
            or => [ and => [_public => 't'],
                    and => [username => $user]
                  ]
        ],
        with_objects => [qw/_report_viewers/],
    );
    $c->set_pages($count);
    $c->stash(objects => $objects);
    $c->stash(favorite_ok => 1 );
    $c->SUPER::list(@_);
};

sub select {
    my $c = shift;
    my $identifier = $c->stash('report_identifier');
    my $report = $c->_this_object or do { $c->render_not_found; return 0; };
    $c->_user_can_view($report) or do { $c->render(status => 403, text => "Forbidden"); return 0; };
    $c->stash(report => $report);
    return 1;
}

sub watch {
    my $c = shift;
    my $limit = $c->param('limit') || 50;
    $limit = 50 unless $limit =~ /^\d+$/;
    my $result = $c->dbc->select(
        [ '*', 'extract(epoch from action_tstamp_tx) as sort_key' ],
        table => "audit.logged_actions",
        append => "order by action_tstamp_tx desc limit $limit",
    );
    my $change_log = $result->all;
    for my $row (@$change_log) {
        my $table = $row->{table_name};
        next if $table =~ /^_/;
        my $class = $c->orm->{$table}{obj} or next;
        my $vals = hstore_decode($row->{row_data});
        if (my $other = $row->{changed_fields}) {
            $other = hstore_decode($other);
            %$vals = ( %$vals, %$other);
        }
        $row->{changed_fields} = decode('UTF-8',$row->{changed_fields}) if defined($row->{changed_fields});
        $row->{obj} = eval { $class->new(%$vals); };

        #$row->{obj}->load(speculative => 1);
    }

    $c->render(template => 'watch', change_log => $change_log);
}

sub update_rel_form {
    my $c = shift;
    $c->stash(relationships => [ map Report->meta->relationship($_), qw/chapters figures findings tables/ ]);
    $c->stash(controls => {
            chapters  => { template => 'one_to_many' },
            figures   => { template => 'one_to_many' },
            findings  => { template => 'one_to_many' },
            tables    => { template => 'one_to_many' }
        });
    $c->SUPER::update_rel_form(@_);
}

sub make_tree_for_show {
    my $c = shift;
    my $report = shift;
    my $pub = $report->get_publication(autocreate => 1);
    my $uri = $report->uri($c);
    my $href = $uri->clone->to_abs;
    $href .= ".".$c->stash('format') if $c->stash('format');
    return {
      files                   => [map $_->as_tree(c => $c), $pub->files],
      uri                     => $uri,
      href                    => $href,
      url                     => $report->url,
      identifier              => $report->identifier,
      publication_year        => $report->publication_year,
      contributors => [map $_->as_tree, $pub->contributors ],
      title        => $report->title,
      doi          => $report->doi,
      report_type_identifier => $report->report_type_identifier,
      chapters     => [
        map +{
          number     => $_->number,
          url        => $_->url,
          title      => $_->title,
          identifier => $_->identifier,
          $c->common_tree_fields($_),
        }, $report->chapters
      ],
    };
}

1;

