#!/usr/bin/env perl
use Mojo::UserAgent;
use Path::Class qw/file/;
use Data::Dumper;

use v5.14;

my $base    = "http://crunchy.local:3000";
my $keyfile = "$ENV{HOME}/.gcis_api_key";
my $key     = file($keyfile)->slurp;
chomp $key;
my $ua      = Mojo::UserAgent->new();
my %hdrs = ("Accept" => "application/json",
            "Authorization" => "Basic $key");

sub get {
    my $path = shift;
    my $tx = $ua->get("$base$path" => \%hdrs);
    while ($tx->res->code == 302) {
        my $location = $tx->res->headers->location;
        say "redirect..to $location";
        $tx = $ua->get($location);
    }
    my $res = $tx->success or die $tx->error;
    my $json = $res->json or die "no json : ".$res->to_string;
    return $res->json;
}

sub post {
    my $path = shift;
    my $data = shift;
    my $tx = $ua->post("$base$path" => \%hdrs => json => $data );
    my $res = $tx->success or die $tx->error.$tx->req->to_string;
    my $json = $res->json or die "no json : ";
    return $res->json;
}

my ($obj,$new);

# Set lat_min for global-slr to -90.
$obj = get("/array/form/update/cc413a99-36db-4fec-a012-d0496eab974b");
say Dumper($obj);
$obj->{rows} = [ [1,2,3], [5,6,7],[11,12,13] ];
post("/array/cc413a99-36db-4fec-a012-d0496eab974b" => $obj);
say Dumper($obj);

