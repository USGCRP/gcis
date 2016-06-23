#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use tlib;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");

$t->ua->max_redirects(1); #login produces a redirect
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })
    ->status_is(200, "Login successful");
$t->ua->max_redirects(0);

my $base = $t->ua->server->url;  #for href check
$base =~ s[/$][];                #strip the last slash, to make tests more readable

$t->get_ok("/relationship/owl:sameAs")
    ->status_is(200, "owl:sameAs is preloaded");

$t->get_ok("/relationship/owl:sameAs# second time" => {Accept => 'application/json'})
    ->json_is('', {identifier => 'owl:sameAs',
                   cited_by =>  [ ],
                   uri => "/relationship/owl:sameAs",
     	           description =>  "An alias",
                   href => "$base/relationship/owl:sameAs.json"}, "owl:sameAs json check");

#Extra comments below are from experimenting with using a hash vs a hashref  -Randall
#my %test_rel = (identifier => 'test:roughlyEquivalent',    #hash
#                description =>  "Close, but not quite");
my $test_rel = {identifier => 'test:roughlyEquivalent',     #hashref
                description =>  "Close, but not quite"};

$t->ua->max_redirects(1); #post produces a redirect
#$t->post_ok("/relationship" => json => \%test_rel)         #hash, referenced
$t->post_ok("/relationship" => json => $test_rel)           #hashref
    ->status_is(200, "Add test:roughlyEquivalent");
$t->ua->max_redirects(0);

$t->get_ok("/relationship/test:roughlyEquivalent.json")
    ->status_is(200, "test:roughlyEquivalent now exists")
    #->json_is('', {%test_rel,                              #hash
    ->json_is('', {%$test_rel,                              #hashref, dereferenced 
                   cited_by =>  [ ],
                   uri => "/relationship/test:roughlyEquivalent",
                   href => "$base/relationship/test:roughlyEquivalent.json"},  "test:roughlyEquivalent json check");

$t->delete_ok("/relationship/test:roughlyEquivalent")->status_is(200, "Deleted test:roughlyEquivalent");

done_testing();

1;
