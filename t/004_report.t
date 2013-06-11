#!perl

use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;

use_ok 'Tuba';

my $t = Test::Mojo->new('Tuba');

# To test 409 conflict
Tuba::Plugin::Db->connection->dbh->{PrintError} = 0;

$t->ua->max_redirects(1);
$t->post_ok('/login' => form => { user => 'unit_test', password => 'anything' })->status_is(200);

$t->post_ok('/report' => form => { identifier => 'test-report' } )->status_is(200);
$t->post_ok('/report' => json => { identifier => 'test-report2' } )->status_is(200);
$t->post_ok('/report' => { Accept => 'application/json' } => json => { identifier => 'test-report2' } )->status_is(409);

$t->get_ok('/report/test-report' => { Accept => 'application/json' } )->status_is(200)
  ->json_is('/identifier' => 'test-report');

$t->get_ok('/report/test-report2' => { Accept => 'application/json' } )->status_is(200)
  ->json_is('/identifier' => 'test-report2');

$t->delete_ok('/report/test-report' => { Accept => 'application/json' })->status_is(200);
$t->delete_ok('/report/test-report2' => { Accept => 'application/json' })->status_is(200);

$t->get_ok('/report/test-report' => { Accept => 'application/json' } )->status_is(404);
$t->get_ok('/report/test-report2' => { Accept => 'application/json' } )->status_is(404);

done_testing();

1;

