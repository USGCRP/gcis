=head1 NAME

Tuba::Image : Controller class for images.

=cut

package Tuba::Image;

use Mojo::Base qw/Mojolicious::Controller/;

sub metadata {
    my $c = shift;
    $c->render_text("testing");
}

1;

