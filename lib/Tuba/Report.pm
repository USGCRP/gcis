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
    $c->SUPER::show(@_);
}

sub list {
    my $c = shift;
    my $user = $c->user;
    my $objects = Reports->get_objects(
        query => [
            or => [ and => [public => 't'],
                    and => [username => $user]
                  ]
        ],
        with_objects => [qw/_report_viewer organization_obj/],
        limit => 20,
    );
    $c->stash(objects => $objects);
    $c->SUPER::list(@_);
};

1;

