#!/usr/bin/env perl
use Mojo::UserAgent;
use Data::Dumper;
use feature qw/:all/;
use strict;

my $ua = Mojo::UserAgent->new();

my $base = $ARGV[0] || 'http://localhost:3000';
my $credsfile = '~/.gcis_creds.'.($ARGV[1] || 'local');

my $all = $ua->get("$base/journal.json?page=1")->success->json;

#http://download.journals.elsevierhealth.com/images/journalimages/1081-1206/S1081120613X00092_cov200h.gif

for my $journal (@$all) {
    say $journal->{title}; 
    my $url = Mojo::URL->new('http://www.google.com')->query(q => $journal->{title}, btnG => 'Search by image');
    #next unless my $url = $journal->{url};
    my $res = $ua->get($url => { Accept => "application/json" })->success or next;
    say $res->body;
    #my ($found) = $res->body =~ /(http.*download.*.gif)/;
    #say $res->body unless $found;
    #say "got ".$journal->{url}." $found";
die;
}

