=head1 NAME

Tuba::Plugin::Auth - Authentication

=head1 SYNOPSIS

 app->plugin('auth');

=head1 DESCRIPTION

Authenticate users.

=cut

package Tuba::Plugin::Auth;
use Mojo::Base qw/Mojolicious::Plugin/;

sub register {
    my ($self, $app, $conf) = @_;

    $app->helper(user => sub {
            my $c = shift;
            $c->session('user');
        } );
    $app->helper(auth => sub {
            my $c = shift;
            return 1 if $c->session('user');
            $c->flash(destination => $c->req->url);
            $c->redirect_to('login');
            return 0;
        });
}


1;


