#!perl

use Test::More tests => 6;
use Test::Mojo;

use_ok 'Tuba';

my $t = Test::Mojo->new('Tuba');

$t->get_ok('/')->status_is(200);

$t->get_ok('/test.html')->content_is("welcome to tuba.\n")->status_is(200);

1;

