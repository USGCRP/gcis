#!/usr/bin/env perl
use Mojo::UserAgent;
use Path::Class qw/file/;
use feature qw/:all/;
use strict;
use warnings;

my $base = 'http://localhost:3000';
my $keyfile = "$ENV{HOME}/.gcis_api_key";

my $key = file($keyfile)->slurp;

my $ua = Mojo::UserAgent->new();

my %h = (
    'Accept' => 'application/json',
    'Authorization' => "Basic $key",
);

my $res = $ua->get("$base/login" => \%h )->res;
my $ok = $res->json;

if ($ok && $ok->{login} eq 'ok') {
    say "successfully logged in";
} else {
    say "failed to login";
    say $res->body;
}



