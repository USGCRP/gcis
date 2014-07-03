#!/usr/bin/env perl


use Mojo::UserAgent;
use Data::Dumper;
use strict;


$| = 1;
my $filter = $ARGV[0];
if ($filter ne "d"   &&    
    $filter ne "r"   &&
    $filter ne "du"  &&
    $filter ne "u"   &&  
    $filter ne "m"   &&
    $filter ne "o"   &&
    $filter ne "") {
    print " error - invalid filter option\n";
    print "   options are: d - no doi, u - no url, r - no redirect, du - no doi url, \n";
    print "                o - all okay, m - urls do not match\n";
    exit;
}
print " filter $filter\n";

my $ua = Mojo::UserAgent->new;
# my $param = "?all=1";
my $param = "";

my $articles = $ua->get("http://data.globalchange.gov/article.json$param")->res->json;

my $i = 0;
for my $article (@$articles) {
    
    # last if $i >= 5;
    $i++;
    # print " $i:\n";

    # print Dumper $article;

    my $uri = $article->{uri};
    # print "   uri $uri\n";

    my $doi = $article->{doi};
    if (!$doi) {
        if ($filter eq "d"  ||
            $filter eq "") {
            print " $i:\n";
            print "   uri $uri\n";
            print "   error - no doi\n"; 
        }
        next;
    }

    my $doi_ref = $ua->get("http://dx.doi.org/$doi")->res->dom;
    # print "   doi_ref $doi_ref\n";
    
    my $redirect = $doi_ref->find('head > title')->text;
    # print "   doi redirect $redirect\n";
    if ($redirect ne "Handle Redirect") {
        if ($filter eq "r"  ||
            $filter eq "") {
            print " $i:\n";
            print "   uri $uri\n";
            print "   doi $doi\n";
            print "   error - no redirect ($redirect)\n"; 
        }
        next;
    }
    
    my $doi_url = $doi_ref->find('body > a[href]')->text;
    if (!$doi_url) {
        if ($filter eq "du"  ||
            $filter eq "") {
            print " $i:\n";
            print "   uri $uri\n";
            print "   doi $doi\n";
            print "   error - no doi url\n"; 
        }
        next;
    }

    my $url = $article->{url};
    if (!$url) {
        if ($filter eq "du"  ||
            $filter eq "") {
            print " $i:\n";
            print "   uri $uri\n";
            print "   doi $doi\n";
            print "   doi_url $doi_url\n";
            print "   error - no url\n";
        }
        next;
    }

    if ($url ne $doi_url) {
        if ($filter eq "m"  ||
            $filter eq "") {
            print " $i:\n";
            print "   uri $uri\n";
            print "   doi $doi\n";
            print "   doi_url $doi_url\n";
            print "   url $url\n";
            print "   error - urls do not match\n"; 
        }
        next;
    }

    if ($filter eq "o"  ||
        $filter eq "") {
        print " $i:\n";
        print "   uri $uri\n";
        print "   doi $doi\n";
        print "   doi_url $doi_url\n";
        print "   url $url\n";
    }
}
