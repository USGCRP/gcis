=head1 NAME

Tuba::Report : Controller class for reports.

=cut

package Tuba::Report;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use Pg::hstore qw/hstore_decode/;
use Encode;
use Tuba::Log;
use List::MoreUtils qw/uniq/;

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

sub render_not_found_or_redirect {
    my $c = shift;
    my $identifier = $c->stash('report_identifier');
    my $sth = $c->db->dbh->prepare(<<'SQL', { pg_placeholder_dollaronly => 1 });
select changed_fields->'identifier'
 from audit.logged_actions where table_name='report' and changed_fields?'identifier'
 and row_data->'identifier' = $1
order by transaction_id limit 1
SQL
    my $got = $sth->execute($identifier);
    my $rows = $sth->fetchall_arrayref;
    return $c->render_not_found unless $rows && @$rows;
    my $replacement = $rows->[0][0];
    my $url = $c->req->url;
    $url =~ s{/report/$identifier(?=/|$)}{/report/$replacement};
    return $c->redirect_to($url);
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('report_identifier');
    my $object = Report->new( identifier => $identifier )
      ->load( speculative => 1, with => [qw/chapters/] )
      or return $c->render_not_found_or_redirect;
    return $c->render(status => 403, text => '403 Forbidden') unless $c->_user_can_view($object);
    $c->stash(object => $object);
    $c->stash(sorters => {
            figures => sub($$) { no warnings; $_[0]->stringify <=> $_[1]->stringify },
            findings => sub($$) { no warnings; $_[0]->stringify <=> $_[1]->stringify },
            tables => sub($$) { no warnings; $_[0]->stringify <=> $_[1]->stringify },
        }
    );

    if ($c->user_can('update')) {
        my $next = Reports->get_objects(
            query => [ identifier => { '>', $object->identifier }],
            sort_by => 'identifier',
            limit => 1,
        );
        $c->stash(next => $next->[0]);

        my $prev = Reports->get_objects(
            query => [ identifier => { '<', $object->identifier }],
            sort_by => 'identifier desc',
            limit => 1,
        );
        $c->stash(prev => $prev->[0]);
    }

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
    if (defined($_ = $c->param('in_library'))) {
        $query{in_library} = $_ if length($_);
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
    my $report = $c->_this_object or do { $c->render_not_found_or_redirect; return 0; };
    $c->_user_can_view($report) or do { $c->render(status => 403, text => "Forbidden"); return 0; };
    $c->stash(report => $report);
    return 1;
}

sub watch {
    my $c = shift;
    my $view = $c->param('view') || 'details';
    $view = 'details' unless $view && $view eq 'summary';

    if ($view eq 'details') {
        my $limit = $c->param('limit') || 50;
        $limit = 50 unless $limit =~ /^\d+$/;
        my $where = ['and'];
        my %where;

        if (my $table = $c->param('t')) {
            if ($table ne 'any') { push @$where,":table_name{=}"; $where{table_name} = $table }
        }
        if (my $type = $c->param('type')) {
            if ($type ne 'changes') { push @$where,":action{=}"; $where{action} = $type; }
        }

        if (my $user = $c->param('user')) { push @$where, ":audit_username{like}"; $where{audit_username} = "%$user%"; }
        if (my $note = $c->param('note')) { push @$where, ":audit_note{like}";     $where{audit_note} = "%$note%";     }

        my $result = $c->dbc->select(
            [ '*', 'extract(epoch from action_tstamp_tx) as sort_key' ],
            table => "audit.logged_actions",
            (@$where > 1 ? 
                ( where => [ $where, \%where ] ) : ()
            ),
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
            $row->{changed_fields} = $row->{changed_fields} if defined($row->{changed_fields});
            $row->{obj} = eval { $class->new(%$vals); };
        }
        $c->stash(change_log => $change_log);
    } else {
        my $cutoff = $c->param('cutoff') || '2 weeks';
        $c->param(cutoff => $cutoff);
        $cutoff = $c->dbc->dbh->quote($cutoff);
        my $result = $c->dbc->select(
            [ 'audit_username', 'table_name', 'count(1) as num' ],
            table => "audit.logged_actions",
            where => "action_tstamp_tx > (now() - interval $cutoff)",
            append => "group by 1,2 order by 1,2"
        );
        my $hashes = $result->fetch_hash_all;
        my $grid;
        do { $grid->{$_->{audit_username}}{$_->{table_name}} = $_->{num} } for @$hashes;
        $c->stash(
          results    => $hashes,
          all_users  => [uniq sort map $_->{audit_username}, @$hashes],
          all_tables => [uniq sort map $_->{table_name}, @$hashes],
          grid => $grid,
        );
    }

    my $template = $view eq 'summary' ? 'watch/summary' : 'watch/details';
    $c->render($template);
}

sub update_rel_form {
    my $c = shift;
    return $c->render(code => 403) unless $c->_user_can_edit($c->_this_object, $c->user);
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
    my %regions;
    if ($pub && $c->param('with_regions')) {
        $regions{regions} = [ map $_->as_tree(c => $c), $pub->regions];
    }
    return {
      %regions,
      files                   => [map $_->as_tree(c => $c), $pub->files],
      uri                     => $uri,
      href                    => $href,
      url                     => $report->url,
      identifier              => $report->identifier,
      publication_year        => $report->publication_year,
      summary                 => $report->summary,
      contributors => [map $_->as_tree(c => $c), $pub->contributors ],
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

for my $method (qw[
update_files_form
update_contributors_form
update_files
put_files
update_contributors
update_keywords
update_regions
update_rel
remove
update 
history
]) {
eval <<DONE;
sub $method {
    my \$c = shift;
    return \$c->render(text => "unauthorized", status => 403) unless \$c->_user_can_edit(\$c->_this_object, \$c->user);
    return \$c->SUPER::$method(\@_);
}
DONE
die $@ if $@;
}

sub _default_order {
    return qw/identifier
    title
    url
    doi
    summary
    publication_year
    in_library
    report_type_identifier
    frequency
    _public
    topic
    contact_note
    contact_email/;
}
1;

