=head1 NAME

Tuba::Book : Controller class for books

=cut

package Tuba::Book;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    $c->stash(extra_cols => [qw/title number_of_pages/]);
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    $c->stash('object', $c->_this_object);
    $c->SUPER::show(@_);
}

sub update_rel_form {
    my $c = shift;
    $c->SUPER::update_rel_form(@_);
}

1;

