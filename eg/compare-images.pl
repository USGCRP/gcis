#!/usr/bin/env perl

use Mojo::UserAgent;
use Data::Dumper;
use strict;

$| = 1;

my $ua = Mojo::UserAgent->new;

my $report = "nca3"

my $images = $ua->get('http://data.globalchange.gov/report/nca3/image.json')->res->json;

for my $image (@$images) {
    my $id = $image->{identifier};
    my $title = $image->{title};
    
    print "image $id  title $title\n";
    sleep 0.01;
}
