=head1 NAME

Tuba::Generic : Controller class for generic publications.

Generic publications just have an hstore and a uuid; they can
have arbitrary key-value pairs associated with them.

=cut

package Tuba::Generic;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $meta = Generic->meta;
    my $identifier = $c->stash('generic_identifier');
    my $object =
      Generic->new( identifier => $identifier )->load( speculative => 1)
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->SUPER::show(@_);
}

1;

