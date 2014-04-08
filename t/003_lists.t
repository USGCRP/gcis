#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::Mojo;

use_ok 'Tuba';

my $t = Test::Mojo->new('Tuba');

$t->get_ok('/report')->status_is(200);
$t->get_ok('/image')->status_is(200);
$t->get_ok('/journal')->status_is(200);
$t->get_ok('/article')->status_is(200);

done_testing();

1;

