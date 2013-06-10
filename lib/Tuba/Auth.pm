=head1 NAME

Tuba::Auth -- controller for authentication

=head1 DESCRIPTION

For now, just looks for a configuration like this :

    auth :
        valid_users :
            user1 : pAsS
            user2 : pAsS2

and accepts the listed users and passwords.  If the
section above does not exist, all username/passwords
are rejected.

=cut

package Tuba::Auth;
use Mojo::Base 'Mojolicious::Controller';

sub login { }

sub check_login {
    my $c = shift;
    my $user = $c->param('user');
    my $password = $c->param('password');
    my $valid_users = $c->config->{auth}{valid_users};
    unless ($valid_users && ref($valid_users) eq 'HASH') {
        $c->app->log->warn("no valid_users hash found in config file, not accepting any credentials");
    } else {
        return $c->_login_ok($user)
             if defined($valid_users->{$user})
                && length($valid_users->{$user})
                && ($password eq $valid_users->{$user});
    }
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

