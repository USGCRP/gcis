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

$t->post_ok("/report/vegetables/chapter/carrots/figure/rel/orange" => json =>
    {delete_image_identifier => $uuid, title => "Orange Carrots"})
  ->status_is(200);

$t->get_ok("/report/vegetables/chapter/carrots/figure/orange.json")->json_is(
    "/images/0/identifier" => undef );

$t->delete_ok("/report/vegetables")->status_is(200);
$t->delete_ok("/image/$uuid")->status_is(200);

done_testing();

1;

