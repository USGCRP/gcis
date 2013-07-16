=head1 NAME

Tuba::Auth -- controller for authentication

=head1 DESCRIPTION

Configuration file looks like this :

    auth :
        valid_users :
            user1 : pAsS
            user2 : pAsS2
        google_secrets_file : /usr/local/etc/client_secrets.json

 valid_users is a list of plaintext usernames and passwords to accept.

 google_secrets_file is JSON downloaded from <https://code.google.com/apis/console/>.

=cut

package Tuba::Auth;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::ByteStream qw/b/;
use Path::Class qw/file/;
use JSON::WebToken qw/decode_jwt/;
use JSON::XS;

sub login {
    my $c = shift;
    return $c->render if $ENV{HARNESS_ACTIVE};
    return $c->render if $c->req->is_secure;
    return $c->render if ($c->app->mode eq 'development' && $c->tx->remote_address eq '127.0.0.1');
    return $c->render if $c->app->mode eq 'development' && $c->tx->remote_address =~ /^192\.168/;
    my $secure = $c->req->url->clone->to_abs;
    $secure->base->scheme('https');
    $secure->scheme('https');
    if (my $dest = ($c->param('destination') || $c->flash('destination') ) ) {
        $secure->query(destination => $dest);
    }
    return $c->redirect_to($secure);
}

sub _google_secrets {
    my $c = shift;
    state $google_secrets;
    return if $google_secrets && $google_secrets eq 'none';
    return $google_secrets->{web} if $google_secrets;
    my $secrets_file = $c->config->{auth}{google_secrets_file};
    if ($secrets_file and !-e $secrets_file) {
        $c->app->log->warn("could not open google_secrets_file $secrets_file");
        $google_secrets = 'none';
        return;
    }
    $google_secrets = JSON::XS->new->decode(scalar file($secrets_file)->slurp);
    return $google_secrets->{web};
}

sub _redirect_uri {
    my $c = shift;
    my $url = $c->req->url->clone->to_abs;
    $url->path('/oauth2callback');
    $url->scheme('https');
    return $url;
}

sub check_login {
    my $c = shift;
    my $user = $c->param('user');
    my $password = $c->param('password');
    return $c->_login_ok($user) if $ENV{HARNESS_ACTIVE};
    return $c->redirect_to('login') unless $user;

    # superusers and development
    my $valid_users = $c->config->{auth}{valid_users};
    if ($valid_users && ref($valid_users) eq 'HASH') {
        return $c->_login_ok($user)
             if defined($valid_users->{$user})
                && length($valid_users->{$user})
                && ($password eq $valid_users->{$user});
    }

    # google oath2
    if (my $w = $c->_google_secrets) {
        my $redirect_uri = $c->_redirect_uri;
        my $auth_state = b(rand())->md5_sum;
        my $redirect_url = Mojo::URL->new($w->{auth_uri})
             ->query(
                client_id       => $w->{client_id},
                response_type => 'code',
                redirect_uri  => $redirect_uri,
                scope         => "openid profile email https://www.googleapis.com/auth/drive.file",
                auth_state    => $auth_state,
                login_hint    => $user,
             );
        $c->flash(auth_state => $auth_state);
        return $c->redirect_to($redirect_url);
    }
    $c->flash(error => "Sorry, bad username or password.");
    $c->redirect_to('login');
}

sub _login_ok {
    my $c = shift;
    my $user = shift;
    $c->app->log->info("Log in ok for $user");
    $c->session(user => $user);
    my $dest = $c->param('destination') || $c->flash('destination') || 'index';
    $dest =~ s/^http(s)?://;
    return $c->redirect_to($dest);
}

sub oauth2callback {
    my $c = shift;
    if (my $error = $c->param('error')) {
        $c->flash(error => "Error : $error (".($c->param('error_description') || 'no description for this error').')');
        return $c->redirect_to('login');
    }
    #my $state = $c->param('state') or return $c->render(code => 401, text => 'invalid auth state');
    #unless ($state eq $c->flash('state')) {
    #    # no server side storage of user data yet, but sessions are signed with HMAC-SHA1
    #    return $c->render(code => 401, text => "invalid auth state");
    #}
    my $code = $c->param('code') or return $c->render(code => 401, text => "missing auth code");

    my $s = $c->_google_secrets;
    my $token_url = $s->{token_uri} or die "no token_url in google_secrets";
    my $tx = $c->ua->post(
        $token_url => form => {
            code          => $code,
            client_id     => $s->{client_id},
            client_secret => $s->{client_secret},
            redirect_uri  => $c->_redirect_uri,
            grant_type    => 'authorization_code'
        }
    );
    my $res = $tx->success or do {
        my ($err,$code) = $tx->error;
        $c->app->log->error("error with google auth : ".$tx->res->to_string);
        return $c->render(code => 401, text => "$code response : $err") if $code;
        return $c->render(code => 401, text => "Connection error : $err");
    };
    my $credentials = $res->json;
    # has access_token, id_token, expires_in, token_type="Bearer"
    my $info = decode_jwt($credentials->{id_token}, "", 0);
    # has exp, iss, email_verified='true', email, sub, azp, lat, at_hash, aud
    return $c->render(code => 401, text => "Invalid aud in JWT") unless $info->{aud} eq $s->{client_id};
    return $c->render(code => 401, text => "Invalid iss in JWT") unless $info->{iss} eq 'accounts.google.com';
    return $c->render(code => 401, text => "email address has not been verified") unless $info->{email_verified} eq 'true';
    # See https://developers.google.com/accounts/docs/OAuth2Login#authenticationuriparameters
    my $user = $info->{email};
    $c->session(google_access_token => b($info->{access_token})->xor_encode($c->app->secret));
    return $c->_login_ok($user);
}

1;

