#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use v5.14;

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");
$t->app->db->dbh->do(q[delete from publication_type where identifier='report']);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('report','report')]);

$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

my $base = $t->ua->server->url;

my %r = (
    identifier => "test-report",
    title      => "Test Report",
    url        => 'http://example.com/foo',
    summary    => 'this is a report',
    doi        => '10.123/45',
    publication_year => '2000',
    report_type_identifier => "",
    contact_note => 'email me if you have problems',
    contact_email => 'nobody@example.com',
);
$t->post_ok( "/report" => form => \%r )->status_is(200);

$t->get_ok("/report/test-report.json")->json_is(
  {%r, uri => "/report/test-report", contributors => [],
      files => [],
      chapters => [],
      href => "${base}report/test-report.json",
      report_type_identifier => 'report',
      report_tables => [],
      report_figures => [],
      report_findings => [],
  }
);

$t->get_ok("/report/test-report.txt")->content_is(" 2000: Test Report, <doi : 10.123/45>");

$t->delete_ok('/report/test-report');

done_testing();

