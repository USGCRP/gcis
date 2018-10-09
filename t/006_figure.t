#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");

$t->app->db->dbh->do(q[delete from publication]);
$t->app->db->dbh->do(q[delete from publication_type]);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('figure','figure')]);

$t->ua->max_redirects(1);
my $server_url = $t->ua->server->url;
$server_url =~ s/\/$//;
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

$t->post_ok("/report.json" => json => {identifier => "vegetables", title => "Veggies"})->status_is(200);

$t->post_ok(
  "/report/vegetables/chapter.json" => json => {
    report_identifier => "vegetables",
    identifier        => "carrots",
    title             => "Carrots"
  }
)->status_is(200);

$t->post_ok(
  "/report/vegetables/chapter/carrots/figure" => { Accept => "application/json" } => json => {
    report_identifier  => "vegetables",
    chapter_identifier => "carrots",
    identifier         => "orange",
    title              => "Orange Carrots",
    url                => 'http://example.com/carrots',
  }
)->status_is(200);

# error handling for create
$t->post_ok(
  "/report/vegetables/chapter/carrots/figure" =>
  { Accept => "application/json"} => json => {
    report_identifier  => "vegetables",
    chapter_identifier => "carrots",
    identifier         => "blue",
    title              => "Blue Carrots",
    uri                => "blue/lagoon",
  }
)->status_is(422)->json_is({error => "uri is not a valid field."});

# error handling for update
$t->post_ok(
  "/report/vegetables/chapter/carrots/figure/orange" =>
  { Accept => "application/json"} => json => {
    report_identifier  => "vegetables",
    chapter_identifier => "carrots",
    identifier         => "blue",
    title              => "Blue Carrots",
    uri                => "blue/lagoon",
  }
)->status_is(422)->json_is({error => "uri is not a valid field."});

my %o = (
   attributes         => undef,
   caption            => undef,
   chapter_identifier => "carrots",
   create_dt         => undef,
   identifier         => "orange",
   lat_max           => undef,
   lat_min           => undef,
   lon_max           => undef,
   lon_min           => undef,
   ordinal           => '41-b',
   report_identifier  => "vegetables",
   source_citation   => undef,
   submission_dt     => undef,
   time_end          => undef,
   time_start        => undef,
   title              => "Orange Carrots!",
   url               => 'http://example.com/carrots.html',
   usage_limits      => undef,
);

# successful update
$t->post_ok(
  "/report/vegetables/chapter/carrots/figure/orange" =>
  { Accept => "application/json" } => json => \%o
)->status_is(200)->json_is(\%o);

my $uuid = "77285d0f-ea9b-4bf2-80aa-3b968420c8b9";

$t->post_ok("/image" => { Accept => "application/json" } => json => { identifier => $uuid } )->status_is(200);

$t->post_ok("/report/vegetables/chapter/carrots/figure/rel/orange" => { Accept => "application/json" } => json =>
    {add_image_identifier => $uuid, title => "Orange Carrots"})
  ->status_is(200);

$t->get_ok("/report/vegetables/chapter/carrots/figure/orange.json")->json_is(
    "/images/0/identifier" => $uuid );

$t->get_ok("/report/vegetables/chapter/carrots/figure/form/update/orange.json")->json_is(\%o
 ) or diag explain($t->tx->res->json);

# List figures across reports
$t->get_ok("/figure.json")->json_is(
[
 { %o,
   'href' => "$server_url/report/vegetables/chapter/carrots/figure/orange.json",
   'uri' => "/report/vegetables/chapter/carrots/figure/orange",
 }
]) or diag explain($t->tx->res->json);

# Create a keyword.
$t->post_ok(
  '/gcmd_keyword', { Accept => "application/json" } => json =>
    {
      identifier => "457883c4-b30c-4d26-bed8-6c2887ebbc90",
      label      => "OCEAN OPTICS",
      definition => "Scientific field of study of light in the oceans. Variables include measurable characteristics of underwater light."
    }
);

# Create a keyword.
$t->post_ok(
  '/gcmd_keyword', { Accept => "application/json" } => json =>
    {
      identifier => "001f18d3-7e61-430b-9883-1960c6256fe5",
      label      => "OPTICAL DEPTH",
      parent_identifier => "457883c4-b30c-4d26-bed8-6c2887ebbc90",
      definition => "The degree to which the ocean absorbs light, assuming vertical separation between light source and light receiver. "
    }
);

# List keywords
$t->get_ok("/gcmd_keyword.json")
  ->status_is(200)
  ->json_is( "/1/identifier", "457883c4-b30c-4d26-bed8-6c2887ebbc90" )
  ->json_is( "/0/identifier", "001f18d3-7e61-430b-9883-1960c6256fe5" );

# Get the children of a keyword
$t->get_ok("/gcmd_keyword/457883c4-b30c-4d26-bed8-6c2887ebbc90/children.json")
  ->status_is(200)
  ->json_is( "/0/identifier", "001f18d3-7e61-430b-9883-1960c6256fe5" )
  ->json_is( "/0/parent_identifier", "457883c4-b30c-4d26-bed8-6c2887ebbc90" );

# Assign it to the figure.
$t->post_ok(
  "/report/vegetables/chapter/carrots/figure/keywords/orange" => { Accept => "application/json" } => json =>
    {identifier => "001f18d3-7e61-430b-9883-1960c6256fe5"})->status_is(200);

$t->get_ok( "/report/vegetables/chapter/carrots/figure/orange.json?with_gcmd=1")
    ->json_is( "/gcmd_keywords/0/identifier", "001f18d3-7e61-430b-9883-1960c6256fe5" );

# Create a region.
$t->post_ok(
  '/region', { Accept => "application/json" } => json =>
    {
      identifier => "bermuda_triangle",
      label      => "Bermuda Triangle",
      description => "The Bermuda Triangle, also known as the Devil's Triangle, is a loosely defined region in the western part of the North Atlantic Ocean, where a number of aircraft and ships are said to have disappeared under mysterious circumstances."
    }
);

# Assign it to the figure.
$t->post_ok(
  "/report/vegetables/chapter/carrots/figure/regions/orange" => { Accept => "application/json" } => json =>
    {identifier => "bermuda_triangle"})->status_is(200);

$t->get_ok( "/report/vegetables/chapter/carrots/figure/orange.json?with_regions=1")
    ->json_is( "/regions/0/identifier", "bermuda_triangle" );

$t->post_ok("/report/vegetables/chapter/carrots/figure/rel/orange" => { Accept => "application/json" } => json =>
    {delete_image_identifier => $uuid, title => "Orange Carrots"})
  ->status_is(200);

$t->get_ok("/report/vegetables/chapter/carrots/figure/orange.json")->json_is(
    "/images/0/identifier" => undef );

# Create a _origination on the figure
$t->post_ok(
  "/report/vegetables/chapter/carrots/figure/orange/original.json" => "{Not Valid JSON"
)->status_is(422);
my %origination = ( identifier => "test_info", foo => "bar", fee => 1 );
$t->post_ok(
  "/report/vegetables/chapter/carrots/figure/orange/original.json" => json => \%origination
)->status_is(200);
$t->get_ok(
  "/report/vegetables/chapter/carrots/figure/orange/original.json"
)->status_is(200)->json_is(\%origination) or diag explain($t->tx->res->json);
$t->delete_ok("/report/vegetables/chapter/carrots/figure/orange/original.json");
$t->delete_ok("/report/vegetables/chapter/carrots/figure/osrange/original.json")->status_is(404);
$t->get_ok(
  "/report/vegetables/chapter/carrots/figure/orange/original.json"
)->status_is(200)->content_is("{}");

$t->delete_ok("/gcmd_keyword/001f18d3-7e61-430b-9883-1960c6256fe5");
$t->delete_ok("/report/vegetables")->status_is(200);
$t->delete_ok("/image/$uuid")->status_is(200);
$t->delete_ok("/region/bermuda_triangle")->status_is(200);

done_testing();

1;

