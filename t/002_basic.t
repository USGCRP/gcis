#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More tests => 23;
# use Test::MBD qw/-autostart/;
# NB: no database changes for these tests.  Uncomment the above line before adding any.
use Test::Mojo;

use_ok 'Tuba';

my $t = Test::Mojo->new('Tuba');

$t->get_ok('/')->status_is(200)->header_is('X-API-Version' => $Tuba::VERSION);

$t->get_ok('/about')->content_like(qr/About the Global Change Information System/)->status_is(200);

$t->get_ok('/api_reference')->status_is(200);
$t->get_ok("/api_reference.json")->json_is('/info/title' => "Global Change Information System")->status_is(200);

$t->get_ok('/uuid?count=3')->status_is(200);
$t->get_ok('/uuid?count=3000')->status_is(200)->content_is("sorry, max is 1000 at once");
$t->get_ok('/uuid.html')->status_is(200);
$t->get_ok('/uuid.text')->status_is(200);
$t->get_ok('/uuid.json')->status_is(200);

1;

