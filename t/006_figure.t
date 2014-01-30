#!perl

use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");

$t->app->db->dbh->do(q[delete from publication_type]);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('figure','figure')]);

$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

$t->post_ok("/report" => json => {identifier => "vegetables"})->status_is(200);

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
    title              => "Orange Carrots"
  }
)->status_is(200);

my $uuid = "77285d0f-ea9b-4bf2-80aa-3b968420c8b9";

$t->post_ok("/image" => json => { identifier => $uuid } )->status_is(200);

$t->post_ok("/report/vegetables/chapter/carrots/figure/rel/orange" => json =>
    {add_image_identifier => $uuid, title => "Orange Carrots"})
  ->status_is(200);

$t->get_ok("/report/vegetables/chapter/carrots/figure/orange.json")->json_is(
    "/images/0/identifier" => $uuid );

$t->get_ok("/report/vegetables/chapter/carrots/figure/form/update/orange.json")->json_is(
 {
   'attributes' => undef,
   'caption' => undef,
   'chapter_identifier' => 'carrots',
   'create_dt' => undef,
   'identifier' => 'orange',
   'lat_max' => undef,
   'lat_min' => undef,
   'lon_max' => undef,
   'lon_min' => undef,
   'ordinal' => undef,
   'report_identifier' => 'vegetables',
   'source_citation' => undef,
   'submission_dt' => undef,
   'time_end' => undef,
   'time_start' => undef,
   'title' => 'Orange Carrots',
   'usage_limits' => undef
 }) or diag explain($t->tx->res->json);

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

$t->post_ok("/report/vegetables/chapter/carrots/figure/rel/orange" => json =>
    {delete_image_identifier => $uuid, title => "Orange Carrots"})
  ->status_is(200);

$t->get_ok("/report/vegetables/chapter/carrots/figure/orange.json")->json_is(
    "/images/0/identifier" => undef );

$t->delete_ok("/gcmd_keyword/001f18d3-7e61-430b-9883-1960c6256fe5");
$t->delete_ok("/report/vegetables")->status_is(200);
$t->delete_ok("/image/$uuid")->status_is(200);

done_testing();

1;

