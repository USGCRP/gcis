=head1 NAME

Tuba::Report : Controller class for reports.

=cut

package Tuba::Report;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $identifier = $c->stash('report_identifier');
    my $meta = Report->meta;
    my $object =
      Report->new( identifier => $identifier )
      ->load( speculative => 1, with => [qw/chapter/] )
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(sorters => {
            figure => sub($$) { no warnings; $_[0]->stringify <=> $_[1]->stringify }
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
            with_objects => [qw/_report_viewer/],
            query => [
                 and => [
                     or => [ and => [public => 't'], and => [username => $user] ],
                     or => [ 'identifier' => { 'le' => 'nca3' } ],
                ]
            ]
        ) / 20 ) + 1;
}

sub list {
    my $c = shift;
    my $user = $c->user;
    my $page = $c->param('page') || 1;
    if ($page eq '♥') {
        $page = $c->_favorite_page;
    };
    $c->stash(page => $page);
    my $objects = Reports->get_objects(
        query => [
            or => [ and => [public => 't'],
                    and => [username => $user]
                  ]
        ],
        with_objects => [qw/_report_viewer organization_obj/],
        page => $page,
        sort_by => 'identifier',
    );
    $c->stash(objects => $objects);
    $c->stash(favorite_ok => 1 );
    $c->SUPER::list(@_);
};

1;

