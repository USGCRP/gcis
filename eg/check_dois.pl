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

    # print Dumper $article;

    my $doi = $article->{doi};
    my $uri = $article->{uri};
    if (!$doi) {
        print " no doi for $uri\n";
        next;
    } else {
        print " doi $doi for uri $uri\n";
    }
    
    my $doi_html = $ua->get("http://dx.doi.org/$doi");
    print Dumper $doi_html;
    
    my $doi_head = $doi_html->res->dom->at('head');
    print " *** head ***\n";
    print Dumper $doi_head;
}
