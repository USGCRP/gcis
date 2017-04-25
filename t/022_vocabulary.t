#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use tlib;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use strict;
use warnings;

note "This tests the top-level vocabulary API (a view of lexicon)";

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");

$t->ua->max_redirects(1); #login produces a redirect
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })
    ->status_is(200, "Login successful");
$t->ua->max_redirects(0); #reset to ignore redirects

my $base = $t->ua->server->url;  #for href check
$base =~ s[/$][];                #strip the last slash, to make tests more readable

$t->get_ok("/vocabulary/ceos")
    ->status_is(200, "ceos is preloaded");

$t->get_ok("/vocabulary/ceos# second time" => {Accept => 'application/json'})
    ->json_is('', {"url" => "http://database.eohandbook.com",
                   "uri" => "/vocabulary/ceos",
                   "display_name" => "ceos",
                   "description" => "Committee on Earth Observation Satellites",
                   "lexicon_identifier" => "ceos",
                   "cited_by" => [ ],
                   "type" => "vocabulary",
                   "parents" => [ ],
                   "href" => "$base/vocabulary/ceos.json"}, "ceos json check");

my $test_vocab_1 = {lexicon_identifier => 'proverbs',
                    description => 'a test vocabulary',
                    url => 'https://en.wiktionary.org/wiki/Category:English_proverbs'};

$t->ua->max_redirects(1); #post produces a redirect
$t->post_ok("/vocabulary" => json => $test_vocab_1)
    ->status_is(200, "Add 'proverbs'")
    ->or (sub {diag explain $t->tx->res->body} ); #Show the body if status != 200
$t->ua->max_redirects(0);

$t->get_ok("/vocabulary/proverbs.json")
    ->status_is(200, "'proverbs' vocabulary now exists")
    ->json_is('', {%$test_vocab_1,
                   "uri" => "/vocabulary/proverbs",
                   "display_name" => "proverbs",
                   "cited_by" => [ ],
                   "type" => "vocabulary",
                   "parents" => [ ],
                   "href" => "$base/vocabulary/proverbs.json"}, "proverbs json check");

$t->delete_ok("/vocabulary/proverbs")->status_is(200, "Deleted proverbs");

$t->get_ok("/vocabulary/proverbs")->status_is(404, "good - proverbs is gone");

$t->post_ok("/vocabulary" => json => $test_vocab_1)
    ->status_is(302, "Add 'proverbs' back in for subsequent tests"); #302 is redirect

done_testing();

1;
