#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use strict;

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");

# To test 409 conflict
Tuba::Plugin::Db->connection->dbh->{PrintError} = 0;

$t->app->db->dbh->do(q[delete from publication_type where identifier='report']);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('report','report')]);

$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);
$t->ua->max_redirects(0);

$t->post_ok("/report" => { Accept => "application/json" } => json => { identifier => 'test-etags', title => 'Etag test' } )->status_is(302);
like $t->tx->res->headers->etag, qr/\w+-\w+-\w+-\w+/;
$t->delete_ok('/report/test-etags');

$t->ua->max_redirects(1);

$t->post_ok("/report" => form => { identifier => "test-report", title => "Test report" } )->status_is(200);
$t->post_ok("/report/test-report/finding" => form => { identifier => "test-finding", statement => "Test Finding." } )->status_is(200);
$t->get_ok("/report/test-report/finding/test-finding.json")->json_is('/statement' => "Test Finding.");

$t->post_ok("/file" => { Accept => "application/json" } => json => { identifier => 'testfile', file => "fake", mime_type => 'foo' } )
    ->status_is(200);

$t->post_ok("/report/files/test-report" => { Accept => "application/json" } => json =>
    {add_existing_file => "/file/testfile"} )->status_is(200);

my $title = "Chapter one ± two";
$t->post_ok("/report/test-report/chapter" => form => { identifier => "test-chapter", title => $title, number => 1 } )->status_is(200);
$t->get_ok("/report/test-report/chapter/form/update/test-chapter.json")
  ->status_is(200)->json_is(
  {
    report_identifier => "test-report",
    identifier        => 'test-chapter',
    title             => $title,
    number            => 1,
    url               => undef,
    sort_key          => undef,
    doi               => undef,
  }
  );

for my $i (1..10) {
    $t->post_ok(
      "/report/test-report/chapter/test-chapter/finding" => form => {
        identifier => "test-chapter-finding-$i",
        ordinal => $i,
        statement  => "Test Chapter Finding number $i."
      }
    )->status_is(200);
    $t->get_ok(
      "/report/test-report/chapter/test-chapter/finding/test-chapter-finding-$i.json"
    )->json_is('/statement' => "Test Chapter Finding number $i.");
}

my $id_num = 11;
for my $s ( @{[ '1a', '2b-1', '3_a', '4.2' ]} ) {
    $t->post_ok(
      "/report/test-report/chapter/test-chapter/finding.json" => form => {
        identifier => "test-chapter-finding-$id_num",
        ordinal => $s,
        statement  => "Test Chapter Finding number $s."
      }
    )->status_is(200);
    $t->get_ok(
      "/report/test-report/chapter/test-chapter/finding/test-chapter-finding-$id_num.json"
    )->json_is('/statement' => "Test Chapter Finding number $s.");
    $id_num++;
}

$t->post_ok("/report" => json => { identifier => "test-report2", title => "test 2 report" } )->status_is(200);
$t->post_ok("/report" => { Accept => "application/json" } => json => { identifier => "test-report2", title => "test 2 report" } )->status_is(409);

$t->get_ok("/report/test-report" => { Accept => "application/json" } )->status_is(200)
  ->json_is("/identifier" => "test-report");

$t->get_ok("/report/test-report2" => { Accept => "application/json" } )->status_is(200)
  ->json_is("/identifier" => "test-report2");

$t->post_ok("/report/test-report/figure" => { Accept => "application/json" } => json => { identifier => "test-figure", report_identifier => "test-report" } )->status_is(200);
$t->get_ok("/report/test-report/figure/test-figure" => { Accept => "application/json" } )->status_is(200)
  ->json_is("/identifier" => "test-figure");

$t->delete_ok("/report/test-report/figure/test-figure" => { Accept => "application/json" } )->status_is(200);
$t->get_ok("/report/test-report/figure/test-figure" => { Accept => "application/json" } )->status_is(404);

$t->get_ok("/report/test-report/figure/" => { Accept => "application/json" } )->status_is(200);
$t->get_ok("/report/test-report/finding/" => { Accept => "application/json" } )->status_is(200);
$t->get_ok("/report/test-report/chapter/" => { Accept => "application/json" } )->status_is(200);
$t->get_ok("/image" => { Accept => "application/json" } )->status_is(200);

# Change the identifier
$t->ua->max_redirects(0);
$t->post_ok("/report/test-report" => { Accept => "application/json" } => json =>
    {
        identifier => "test-report-changed",
        title => "changed",
    })->status_is(200);
$t->get_ok("/report/test-report")->status_is(302);

$t->ua->max_redirects(1);

$t->delete_ok("/file/testfile" => { Accept => "application/json" } )->status_is(200);
$t->delete_ok("/report/test-report-changed" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/report/test-report2")->status_is(200);

$t->get_ok("/report/test-report" => { Accept => "application/json" } )->status_is(404);
$t->get_ok("/report/test-report2" => { Accept => "application/json" } )->status_is(404);

done_testing();

1;

