#!perl

use Test::More;
use Test::Mojo;

use_ok 'Tuba';

my $t = Test::Mojo->new('Tuba');

$t->get_ok('/chapter')->status_is(200);
$t->get_ok('/figure')->status_is(200);
$t->get_ok('/image')->status_is(200);

done_testing();

1;

