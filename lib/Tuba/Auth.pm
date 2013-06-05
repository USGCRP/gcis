package Tuba::Auth;
use Mojo::Base qw/Mojolicious::Controller/;

sub check {
    my $c = shift;
    return 1 if $c->auth;
    $c->redirect('
}

