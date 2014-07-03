#!/usr/bin/env perl


use Mojo::UserAgent;
use Data::Dumper;
use strict;


$| = 1;
my $filter = $argv[0];
if ($filter ne "d"   &&  
    $filter ne "u"   &&  
    $filter ne "r"   &&
    $filter ne "du"  &&
    $filter ne "m"   &&
    $filter ne "") {
    print " error - invalid filter option\n";
    print "   options are: d - no doi, u - no url, r - no redirect, du - no doi url, m - urls do not match\n";
    exit;
}
print " filter $filter";

my $ua = Mojo::UserAgent->new;
my $param = "?all=1";


my $articles = $ua->get("http://data.globalchange.gov/article.json$param")->res->json;

my $i = 0;
for my $article (@$articles) {
    
    # last if $i >= 5;
    $i++;
    print " $i:\n";

    # print Dumper $article;

    my $uri = $article->{uri};
    print "   uri $uri\n";

    my $doi = $article->{doi};
    if (!$doi) {
        print "   error - no doi\n"; next;
    }
    print "   doi $doi\n";
    
    my $doi_ref = $ua->get("http://dx.doi.org/$doi")->res->dom;
    # print "   doi_ref $doi_ref\n";
    
    my $redirect = $doi_ref->find('head > title')->text;
    # print "   doi redirect $redirect\n";
    if ($redirect ne "Handle Redirect") {
        print "   error - no redirect ($redirect)\n"; next;
    }
    
    my $doi_url = $doi_ref->find('body > a[href]')->text;
    if (!$doi_url) {
        print "   error - no doi url\n"; next;
    }
    print "   doi_url $doi_url\n";
    
    my $url = $article->{url};
    if (!$url) {
        print "   error - no url\n"; next;
    }
    print "   url $url\n";
    
    if ($url ne $doi_url) {
        print "   error - urls do not match\n"; next;
    }

}
