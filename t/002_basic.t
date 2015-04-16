#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More tests => 9;
use Test::Mojo;

use_ok 'Tuba';

my $t = Test::Mojo->new('Tuba');

$t->get_ok('/')->status_is(200)->header_is('X-API-Version' => $Tuba::VERSION);

$t->get_ok('/test.html')->content_is("This is the GCIS API.\n")->status_is(200);

$t->get_ok('/api_reference')->status_is(200);

1;

