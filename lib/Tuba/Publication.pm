=head1 NAME

Tuba::Publication : Controller class for publications.

=cut

package Tuba::Publication;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $identifier = $c->stash('publication_identifier');
    my $pub = Publication->new( id => $identifier )->load( speculative => 1)
      or return $c->render_not_found;
    my $object = $pub->to_object;
    return $c->redirect_to($object->uri($c)->to_abs);
}

1;

