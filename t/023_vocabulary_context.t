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

note "This tests the API for the context of a specific vocabulary";

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");

$t->ua->max_redirects(1); #login produces a redirect
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })
    ->status_is(200, "Login successful");
$t->ua->max_redirects(0); #reset to ignore redirects

my $base = $t->ua->server->url;  #for href check
$base =~ s[/$][];                #strip the last slash, to make tests more readable

$t->get_ok("/vocabulary/proverbs")
    ->status_is(200, "proverbs is there")
    ->or(sub {plan skip_all => "==>> This test depends on prior test!        <<==\n".
                     "          ==>> Make sure you have run 022_vocabulary.t <<=="});


my $test_context = {"lexicon_identifier" => "proverbs",
                    "identifier" => "number",
                    #"version" => "",         #version is not used, defaults to ''
                    "description" => "Numbers used in proverbs",
                    "url" => "https://en.wiktionary.org/wiki/Category:en:Numbers"};
 
$t->ua->max_redirects(1); #post produces a redirect
$t->post_ok("/vocabulary/proverbs" => json => $test_context)
    ->status_is(200, "Add context 'number' in vocabulary 'proverbs'")
    ->or(sub { diag explain $t->tx->res->body });
$t->ua->max_redirects(0);

$t->get_ok("/vocabulary/proverbs/number.json")
    ->status_is(200, "'number' context now exists")
    ->json_is('', {%$test_context,
               "href" => "$base/vocabulary/proverbs/number.json",
               "parents" => [ ],
               "cited_by" => [ ],
               "type" => "context",
               "version" => "",             #even though version is not used, it is still returned
               "display_name" => "proverbs/number/",
               "uri" => "/vocabulary/proverbs/number"}, "number json check");

$t->delete_ok("/vocabulary/proverbs/number")->status_is(200, "Deleted number");

$t->get_ok("/vocabulary/proverbs/number")->status_is(404, "good - number is gone");

$t->post_ok("/vocabulary/proverbs" => json => $test_context)
    ->status_is(302, "Add 'number' back in for subsequent tests"); #302 is redirect

done_testing();

1;

