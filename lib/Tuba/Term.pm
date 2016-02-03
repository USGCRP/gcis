=head1 NAME

Tuba::Term : Controller class for terms.

=cut

package Tuba::Term;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $identifier = $c->stash('term_identifier');
    my $object = Term->new (identifier => $identifier )
      -> load( speculative => 1 ) or return $c->reply->not_found;
    $c->stash( object => $object );
    $c->SUPER::show(@_);
}

1;
