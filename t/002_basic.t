#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More tests => 7;
use Test::Mojo;

use_ok 'Tuba';

my $t = Test::Mojo->new('Tuba');

diag "public path : ".$t->app->static->paths->[0];
diag "template path : ".$t->app->renderer->paths->[0];
diag "Tuba.pm : ".$INC{'Tuba.pm'};

$t->get_ok('/')->status_is(200)->header_is('X-API-Version' => $Tuba::VERSION);

$t->get_ok('/test.html')->content_is("This is the GCIS API.\n")->status_is(200);


1;

