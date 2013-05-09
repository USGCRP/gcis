#!perl

use Test::More tests => 3;
use Test::Mojo;

use_ok 'Tuba';

my $t = Test::Mojo->new('Tuba');

$t->get_ok('/')->status_is(200);

1;

