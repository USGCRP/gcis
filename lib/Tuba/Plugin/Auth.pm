=head1 NAME

Tuba::Plugin::Auth - Authentication

=head1 SYNOPSIS

 app->plugin('auth' => $config);

=head1 DESCRIPTION

Set up helpers for auth, and set $app->secret using config->{auth}{secret}.

=cut

package Tuba::Plugin::Auth;
use Mojo::Base qw/Mojolicious::Plugin/;

sub register {
    my ($self, $app, $conf) = @_;

    $app->helper(user => sub {
            my $c = shift;
            $c->session('user');
        } );
    $app->helper(user_short => sub {
            my $c = shift;
            my $u = $c->session('user');
            $u =~ s/@.*$//;
            return $u;
        } );

    $app->helper(auth => sub {
            my $c = shift;
            return 1 if $c->session('user');
            $c->flash(destination => $c->req->url);
            $c->redirect_to('login');
            return 0;
        });
    $app->secret($conf->{secret});
}


1;


