=head1 NAME

Tuba::Webpage : Controller class for webpage (publication type)

=cut

package Tuba::Webpage;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $webpage = $c->_this_object or return $c->render_not_found_or_redirect;
    $c->stash(object => $webpage);
    $c->SUPER::show(@_);
}

sub update_rel_form {
    my $c = shift;
    $c->SUPER::update_rel_form(@_);
}

1;

