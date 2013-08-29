#!/usr/bin/env perl

use Mojo::JSON;
use Mojo::UserAgent;
use File::Temp;
use feature qw/:all/;
use strict;

my $base = $ARGV[0] || 'http://localhost:3000';
my $credsfile = '~/.gcis_creds.'.($ARGV[1] || 'local');
my $page = $ARGV[2] || '1';

my $ua = Mojo::UserAgent->new;

my $json = $ua->get("$base/report.json?page=$page")->res->json;

my $creds = `cat $credsfile`;
chomp $creds;

my $dir;
for (@$json) {
    $dir = File::Temp->newdir;
    chdir $dir;
    my $identifier = $_->{identifier};
    my $url = $_->{url} or next;
    say "\n\n\n";
    say "$identifier : $url";
    say `curl -q '$url' > ./got.pdf`;
    -e './got.pdf' or next;
    say `pdftoppm -f 1 -l 1 ./got.pdf ./firstpage`;
    -e './firstpage-001.ppm' or next;
    say `convert ./firstpage-001.ppm ./firstpage.jpg`;
    -e './firstpage.jpg' or next;
    say `curl -T ./firstpage.jpg -u $creds $base/report/files/$identifier`;
} continue {
    chdir '/tmp';
    undef $dir;
}


