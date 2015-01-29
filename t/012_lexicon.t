#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");

$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(302);

# Agency
my $gcid = "/organization/european-space-agency";
#  Send lexicon, term and context to map to a GCID.
$t->post_ok("/lexicon/ceos/term/new" => {Accept => "application/json"} => json =>
    {term => 'ESA', context => "Agency", gcid => $gcid})
  ->status_is(200)
  ->json_is({status => 'ok'});

$t->post_ok("/lexicon/ceos/term/new" => {Accept => "application/json"} => json =>
    {term => 'NASA', context => "Agency", gcid => '/organization/national-aeronatics-and-space-administration'})
  ->status_is(200)
  ->json_is({status => 'ok'});

$t->get_ok('/lexicon/ceos/list/Agency' => {Accept => 'application/json'})
    ->status_is(200)
    ->json_is([
            { term => 'ESA', gcid => $gcid },
            { term => 'NASA', gcid => "/organization/national-aeronatics-and-space-administration" },
        ]);

$t->get_ok("/lexicon/ceos/find/Agency/ESA")
  ->status_is(303)                  # 303 == "See Other"
  ->header_is(Location => $gcid)
  ->content_like(qr/\Q$gcid\E/);    # The content SHOULD have a link, says RFC 2616

$t->delete_ok("/lexicon/ceos/Agency/ESA")
  ->status_is(200);

$t->get_ok("/lexicon/ceos/find/Agency/ESA")
  ->status_is(404);

# Platform
$gcid = "/platform/aqua";

$t->post_ok("/lexicon/ceos/term/new" => {Accept => "application/json"} => json =>
    {term => 'Aqua (with stuff here)', context => "Mission", gcid => $gcid})
  ->status_is(200)
  ->json_is({status => 'ok'});

$t->get_ok("/lexicon/ceos/find/Mission/Aqua (with stuff here)")
  ->status_is(303)                  # 303 == "See Other"
  ->header_is(Location => $gcid)
  ->content_like(qr/\Q$gcid\E/);    # The content SHOULD have a link, says RFC 2616

$t->get_ok("/lexicon/ceos/find/Mission/Aqua (with stuff here)" => {Accept => "application/json"})
  ->status_is(303)                  # 303 == "See Other"
  ->json_is({gcid => $gcid});

$t->get_ok("/lexicon/ceos.nt")->content_unlike(qr/error converting to ntriples/)
  ->status_is(200, "No errors making ntriples");

$t->delete_ok("/lexicon/ceos/Mission/Aqua (with stuff here)")
  ->status_is(200);

$t->get_ok("/lexicon/ceos/find/Mission/Aqua")
  ->status_is(404);


done_testing();

1;

