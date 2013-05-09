#!perl

use Test::MBD;
use Test::More tests => 1;

ok 1, 'stopping database';

Test::MBD->stop;

