=head1 NAME

Tuba::Journal : Controller class for journals.

=cut

package Tuba::Journal;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $meta = Journal->meta;
    my $identifier = $c->stash('journal_identifier');
    my $object =
      Journal->new( identifier => $identifier )->load( speculative => 1)
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->SUPER::show(@_);
}

1;

