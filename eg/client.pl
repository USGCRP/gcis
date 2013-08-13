#!/usr/bin/env perl
use Mojo::UserAgent;
use feature qw/:all/;
use strict;
use warnings;

my $base = 'http://localhost:3000';
my $keyfile = "$ENV{HOME}/.gcis_api_key";

my $key = Mojo::Asset::File->new( path => $keyfile )->slurp;

my $ua = Mojo::UserAgent->new();

my %h = (
    'Accept' => 'application/json',
    'X-GCIS-API-Key' => $key
);

my $res = $ua->get("$base/login" => \%h )->res;
my $ok = $res->json;

if ($ok && $ok->{login} eq 'ok') {
    say "successfully logged in";
} else {
    say "failed to login";
    say $res->body;
}



