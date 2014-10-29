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
use Mojo::JSON;
use Time::Duration qw/ago/;
use Tuba::Log;
use Data::Dumper;

my $key_expiration = 60 * 60 * 24 * 30;

sub check_api_key {
    my $c = shift;
    my $auth = $c->req->headers->authorization or return 0;
    my ($api_key) = $auth =~ /^Basic (.*)$/;
    if($c->Tuba::Auth::_validate_api_key($api_key)) {
        return 1;
    }
    return 0;
}

sub _validate_api_key {
    # Also sets session->{user} on success.
    my $c = shift;
    my $key = shift or return 0;
    my $secret = $c->config('auth')->{secret};
    my ($user,$hashtime) = split q[:], b($key)->b64_decode;
    unless ($user) {
        logger->warn("missing user in key $key");
        return 0;
    }
    my ($hash,$create_time) = (substr($hashtime,0,40),substr($hashtime,40));
    $create_time = hex $create_time;
    unless ($create_time =~ /^[0-9]+$/) {
        logger->warn("Invalid time in api key : ".($create_time // 'none'));
        return 0;
    }
    if (time - $create_time > $key_expiration) {
        logger->warn("Key for $user expired ".ago(time - $create_time));
        return 0;
    }
    my $verify = b(Mojo::JSON::encode_json([$user,$secret,$create_time]))->hmac_sha1_sum;
    if ($verify eq $hash) {
        logger->debug("Valid api key for $user, created ".ago(time - $create_time));
        $c->session(user => $user);
        return 1;
    } else {
        logger->warn("Invalid key for $user");
    }
    return 0;
}

sub login {
    my $c = shift;
    $c->respond_to(
        json => sub { shift->stash->{format} = 'json' },
        html => sub { shift->stash->{format} = 'html' }
    );
    my $api_key = $c->param('api_key');
    if (my $auth = $c->req->headers->authorization) {
        ($api_key) = $auth =~ /^Basic (.*)$/;
    }
    if ($api_key) {
        if ($c->_validate_api_key($api_key)) {
            return $c->respond_to(
                json => sub { shift->render( json => { login => "ok" } ) },
                html => sub { shift->render( text => "login ok\n" ) } 
            );
        }
    }
    return $c->render if $ENV{HARNESS_ACTIVE};
    return $c->render if $c->req->is_secure;
    return $c->render if ($c->app->mode eq 'development' && $c->tx->remote_address eq '127.0.0.1');
    return $c->render if $c->app->mode eq 'development' && $c->tx->remote_address =~ /^192\.168/;
    return $c->render if $c->app->mode eq 'development' && $ENV{TUBA_ALLOW_INSECURE_LOGINS};
    my $secure = $c->req->url->clone->to_abs;
    $secure->base->scheme('https');
    $secure->scheme('https');
    if (my $dest = ($c->param('destination') || $c->flash('destination') ) ) {
        $secure->query(destination => $dest);
    }
    if ($secure->host =~ /www.gcis-dev-front/) {
        my $host = $secure->host;
        $host =~ s/www/data/;
        $secure->host($host);
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
    my $url = $c->req->url->to_abs->clone;
    $url->path('/oauth2callback');
    $url->scheme('https');
    $url->query(Mojo::Parameters->new());
    return $url->to_abs;
}

sub check_login {
    my $c = shift;
    my $user = $c->param('user');
    if (!$user && (my $json = $c->req->json)) {
        $user = $json->{user};
    }
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

    my $destination = $c->param('destination') || 'login';
    # google oath2
    if (my $w = $c->_google_secrets) {
        my $redirect_uri = $c->_redirect_uri;
        my $redirect_url = Mojo::URL->new($w->{auth_uri})
             ->query(
                client_id       => $w->{client_id},
                response_type => 'code',
                redirect_uri  => $redirect_uri,
                scope         => "openid profile email https://www.googleapis.com/auth/drive.file",
                state         => $destination,
                login_hint    => $user,
             );
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
    if (my $state = $c->param('state')) {
        $c->param(destination => $state);
    }

    my $code = $c->param('code') or return $c->render(code => 401, text => "missing auth code");

    my $s = $c->_google_secrets;
    my $token_url = $s->{token_uri} or die "no token_url in google_secrets";
    my $tx = $c->ua->post(
        $token_url => form => {
            code          => $code,
            client_id     => $s->{client_id},
            client_secret => $s->{client_secret},
            redirect_uri  => $c->_redirect_uri,
            grant_type    => 'authorization_code',
        }
    );
    my $res = $tx->success or do {
        my $err = $tx->error;
        $c->app->log->error("error with google auth ($token_url) : ".$tx->res->to_string);
        $c->app->log->error("request : ".$tx->req->to_string);
        return $c->render(code => 401, text => "$err->{code} response : $err->{message}") if $code;
        return $c->render(code => 401, text => "Connection error : $err->{message}");
    };
    my $credentials = $res->json;
    # has access_token, id_token, expires_in, token_type="Bearer"
    my $info = decode_jwt($credentials->{id_token}, "", 0);
    # has exp, iss, email_verified='true', email, sub, azp, lat, at_hash, aud
    return $c->render(code => 401, text => "Invalid aud in JWT") unless $info->{aud} eq $s->{client_id};
    return $c->render(code => 401, text => "Invalid iss in JWT") unless $info->{iss} eq 'accounts.google.com';
    return $c->render(code => 401, text => "email address has not been verified") unless $info->{email_verified};
    # $c->app->log->info("google info : ".Dumper($info));
    # See https://developers.google.com/accounts/docs/OAuth2Login#authenticationuriparameters
    my $user = $info->{email};
    $c->session(google_access_token => b($info->{access_token}));
    return $c->_login_ok($user);
}

sub make_api_key {
    my $c = shift;
    my $time = time;
    my $secret = $c->config('auth')->{secret};
    my $user = $c->user;
    my $hash = b(Mojo::JSON::encode_json([$user,$secret,$time]))->hmac_sha1_sum;
    my $api_pw = sprintf('%s%x',$hash,$time);
    my $api_key = b(sprintf('%s:%s',$user,$api_pw))->b64_encode->to_string;
    $api_key =~ s/\n//g;
    return ($api_pw,$api_key);
}

sub login_key {
    my $c = shift;
    unless ($c->user) {
        return $c->respond_to(
            json => sub { shift->render( json => { error => 'not logged in' } ) },
            any  => sub { shift->render(api_user => "", api_pw => "", api_key => ""); },
        );
    }
    my ($api_pw,$api_key) = $c->make_api_key;
    $c->stash(api_user => $c->user);
    $c->stash(api_pw => $api_pw);
    $c->stash(api_key => $api_key);
    logger->debug("api key for ".$c->user." : $api_key");
    return $c->respond_to(
        json => sub { shift->render(json => { userinfo => (join ':',$c->user,$api_pw), key => $api_key } ) },
        yaml => sub { shift->render; },
        any => sub { shift->render; }
    );
}

1;

