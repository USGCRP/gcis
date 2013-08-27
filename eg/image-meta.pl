#!/usr/bin/env perl
use Mojo::UserAgent;
use Path::Class qw/file/;
use Data::Dumper;

use feature qw/:all/;
use strict;
use warnings;

my $base    = "http://localhost:3000";
my $keyfile = "$ENV{HOME}/.gcis_api_key";
my $key     = file($keyfile)->slurp;
chomp $key;
my $ua      = Mojo::UserAgent->new();
my %hdrs = ("Accept" => "application/json",
            "Authorization" => "Basic $key");

sub get {
    my $path = shift;
    my $tx = $ua->get("$base$path" => \%hdrs);
    my $res = $tx->success or die $tx->error;
    my $json = $res->json or die "no json : ".$res->body;
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
$obj = get("/report/nca3draft/figure/form/update/global-slr");
$obj->{lat_min} = "-90";
post("/report/nca3draft/figure/global-slr" => $obj);

# Set bounding box and url for coastal-flooding-new-jersey
$obj = get("/report/nca3draft/figure/form/update/coastal-flooding-new-jersey");
%$obj = (
    %$obj,
    lat_min => "40.20",
    lat_max => "38.87",
    long_min => "-74.00",
    long_max => "-74.98",
    source_citation => "http://coastal.er.usgs.gov/hurricanes/sandy/coastal-change/"
);
post("/report/nca3draft/figure/coastal-flooding-new-jersey" => $obj);
