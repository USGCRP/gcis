#!/usr/bin/env perl


use Mojo::UserAgent;
use Data::Dumper;
use strict;


$| = 1;


my $ua = Mojo::UserAgent->new;


my $articles = $ua->get('http://data.globalchange.gov/article.json')->res->json;

my $i = 0;
for my $article (@$articles) {
    last if $i > 5;
    $i++;
    print " i $i\n";

    my $url = $article->{url};
    my $doi = $article->{doi};
    next unless $doi && $url;
    next if $url =~ /dx.doi.org/;
    my $doi_redirect = $ua->get("http://dx.doi.org/$doi")->res->headers->location;
    next if $url eq $doi_redirect;
    print "Different urls for $doi : $url $doi_redirect\n";

}
