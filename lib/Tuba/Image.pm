=head1 NAME

Tuba::Image : Controller class for images.

=cut

package Tuba::Image;

use Mojo::Base qw/Mojolicious::Controller/;

=head1 ROUTES

=head2 list

Get a list of images.

=cut

=head2 met

=cut

sub met {
    my $c = shift;
    $c->respond_to(json => sub { shift->render_json({ todo => 'todo' }) }, html => sub { shift->render_text("todo")});
}

=head2 display

=cut

sub display { }


sub setmet { }

1;

