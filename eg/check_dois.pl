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
    print " $i:\n";

    # print Dumper $article;

    my $uri = $article->{uri};
    print "   uri $uri\n";

    my $doi = $article->{doi};
    if (!$doi) {
        print "   error - no doi\n";
        next;
    } else {
        print "   doi $doi\n";
    }
    
    my $doi_ref = $ua->get("http://dx.doi.org/$doi")->res->dom;
    print Dumper $doi_ref;
    
    my $redirect = $doi_ref->find('head > title')->text;
    print " redirect $redirect\n";
    if ($redirect != "Handle Redirect") {
        print "   error - no redirect\n";
    }
}
