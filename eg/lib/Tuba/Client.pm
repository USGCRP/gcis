package Tuba::Client;
use Mojo::UserAgent;
use Mojo::Base -base;
use Path::Class qw/file/;
use v5.14;

has url    => 'http://localhost:3000';
has keyfile => sub { $ENV{HOME}.'/.gcis_api_key' };
has key    => sub { state $key ||= do { $a = file(shift->keyfile)->slurp; chomp $a; $a; }; $key; };
has ua     => sub { state $ua ||= Mojo::UserAgent->new(); $ua; };
has hdrs   => sub { {"Accept" => "application/json", "Authorization" => "Basic ".shift->key} };

sub get {
    my $s = shift;
    my $path = shift;
    my $tx = $s->ua->get($s->url."$path" => $s->hdrs);
    while ($tx->res->code == 302) {
        my $location = $tx->res->headers->location;
        say "redirect..to $location";
        $tx = $s->ua->get($location);
    }
    my $res = $tx->success or die $tx->error;
    my $json = $res->json or die "no json : ".$res->to_string;
    return $res->json;
}

sub post {
    my $s = shift;
    my $path = shift;
    my $data = shift;
    my $tx = $s->ua->post($s->url."$path" => $s->hdrs => json => $data );
    my $res = $tx->success or say $tx->error.$tx->req->to_string;
    say "$path : ".$tx->res->code;
    return unless $res;
    my $json = $res->json or return;
    return $res->json;
}

1;
