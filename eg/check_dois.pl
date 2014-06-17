#!/usr/bin/env perl


use Mojo::UserAgent;
use Data::Dumper;
use strict;


$| = 1;


my $ua = Mojo::UserAgent->new;


my $articles = $ua->get('http://data.globalchange.gov/article.json')->res->json;

my $i = 0;
for my $article (@$articles) {
    
    last if $i > 0;
    $i++;
    print " i $i\n";

    print Dumper $article;

    my $doi = $article->{doi};
    if (!$doi) {
        my $uri = $article->{uri};
        print " no doi for $uri\n";
        next;
    }
    my $doi_redirect = $ua->get("http://dx.doi.org/$doi")->res->headers->location;
    print " doi redirect $doi_redirect\n";
}
