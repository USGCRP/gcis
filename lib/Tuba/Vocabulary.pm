=head1 NAME

Tuba::Vocabulary - Controller for lexicons through /vocabulary.

=cut

package Tuba::Vocabulary;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use Tuba::Log qw/logger/;

sub _default_list_order {
    return "lexicon_identifier";
}

sub show {
    my $c = shift;
    my $lexicon = $c->_this_object or return $c->render_not_found_or_redirect;
    $c->stash(object => $lexicon);
    $c->SUPER::show(@_);
}

1;
