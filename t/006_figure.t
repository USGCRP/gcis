#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use Data::Dumper;

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");

$t->app->db->dbh->do(q[delete from publication]);
$t->app->db->dbh->do(q[delete from publication_type]);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('figure','figure')]);

$t->ua->max_redirects(1);
my $server_url = $t->ua->server->url;
$server_url =~ s/\/$//;
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

$t->post_ok("/report" => json => {identifier => "vegetables", title => "Veggies"})->status_is(200);

$t->post_ok(
  "/report/vegetables/chapter" => json => {
    report_identifier => "vegetables",
    identifier        => "carrots",
    title             => "Carrots"
  }
)->status_is(200);

$t->post_ok(
  "/report/vegetables/chapter/carrots/figure" => json => {
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

my %added_tags = (   #JSON tags added by the API
   chapter      => {display_name => 'Carrots'},
   description  => undef,
   display_name => "-.41-b: Orange Carrots!",
   report       => {display_name => 'Veggies'},
   type         => 'figure',
);

# successful update
$t->post_ok(
  "/report/vegetables/chapter/carrots/figure/orange" =>
  { Accept => "application/json" } => json => \%o
)->status_is(200)->json_is({%o,
                            %added_tags,
                          })
->or(sub { diag "Full JSON is\n" . Dumper $t->tx->res->json });

my $uuid = "77285d0f-ea9b-4bf2-80aa-3b968420c8b9";

$t->post_ok("/image" => json => { identifier => $uuid } )->status_is(200);

$t->post_ok("/report/vegetables/chapter/carrots/figure/rel/orange" => json =>
    {add_image_identifier => $uuid, title => "Orange Carrots"})
  ->status_is(200);

$t->get_ok("/report/vegetables/chapter/carrots/figure/orange.json")->json_is(
    "/images/0/identifier" => $uuid );

$t->get_ok("/report/vegetables/chapter/carrots/figure/form/update/orange.json")->
            json_is({%o,
                     %added_tags,
                    }
 )-> or (sub {diag "Full JSON is\n"; diag Dumper($t->tx->res->json)});
#I prefer Data::Dumper to explain() since Dumper shows hash in the order json_is evaluated it

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
  '/gcmd_keyword', json =>
    {
      identifier => "001f18d3-7e61-430b-9883-1960c6256fe5",
      label      => "OPTICAL DEPTH",
      definition => "The degree to which the ocean absorbs light, assuming vertical separation between light source and light receiver. "
    }
);

# Assign it to the figure.
$t->post_ok(
  "/report/vegetables/chapter/carrots/figure/keywords/orange" => json =>
    {identifier => "001f18d3-7e61-430b-9883-1960c6256fe5"})->status_is(200);

$t->get_ok( "/report/vegetables/chapter/carrots/figure/orange.json?with_gcmd=1")
    ->json_is( "/gcmd_keywords/0/identifier", "001f18d3-7e61-430b-9883-1960c6256fe5" );

# Create a region.
$t->post_ok(
  '/region', json =>
    {
      identifier => "bermuda_triangle",
      label      => "Bermuda Triangle",
      description => "The Bermuda Triangle, also known as the Devil's Triangle, is a loosely defined region in the western part of the North Atlantic Ocean, where a number of aircraft and ships are said to have disappeared under mysterious circumstances."
    }
);

# Assign it to the figure.
$t->post_ok(
  "/report/vegetables/chapter/carrots/figure/regions/orange" => json =>
    {identifier => "bermuda_triangle"})->status_is(200);

$t->get_ok( "/report/vegetables/chapter/carrots/figure/orange.json?with_regions=1")
    ->json_is( "/regions/0/identifier", "bermuda_triangle" );

$t->post_ok("/report/vegetables/chapter/carrots/figure/rel/orange" => json =>
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

