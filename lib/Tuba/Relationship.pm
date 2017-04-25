=head1 NAME

Tuba::Relationship : Controller class for relationships

=cut

package Tuba::Relationship;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $identifier = $c->stash('relationship_identifier');
    my $object = Relationship->new (identifier => $identifier )
      -> load( speculative => 1 ) or return $c->reply->not_found;
    $c->stash( object => $object );
    $c->SUPER::show(@_);
}

1;
