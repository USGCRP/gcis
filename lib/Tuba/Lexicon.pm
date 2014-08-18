=head1 NAME

Tuba::Lexicon - Controller for lexcons.

=cut

package Tuba::Lexicon;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $lexicon = $c->_this_object or return $c->render_not_found_or_redirect;
    $c->stash(object => $lexicon);
    $c->SUPER::show(@_);
}

1;

