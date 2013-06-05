=head1 NAME

Tuba::Auth -- controller for authentication

=cut

package Tuba::Auth;
use Mojo::Base 'Mojolicious::Controller';

sub login {

}

sub check_login {
    my $c = shift;
    my $user = $c->param('user');
    my $password = $c->param('password');
    return $c->_login_ok($user) if $user && $password eq 'tuba';
    $c->flash(error => "Sorry, bad username or password.");
    $c->redirect_to('login');
}

sub _login_ok {
    my $c = shift;
    my $user = shift;
    $c->app->log->info("Log in ok for $user");
    $c->session(user => $user);
    my $dest = $c->param('destination') || 'index';
    return $c->redirect_to($dest);
}

1;

