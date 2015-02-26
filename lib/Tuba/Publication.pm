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
      or return $c->reply->not_found;
    my $object = $pub->to_object or return $c->reply->not_found;
    return $c->redirect_to($object->uri($c)->to_abs);
}

1;

