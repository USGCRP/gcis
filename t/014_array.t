#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");
$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

$t->post_ok(
  "/array" => form => {
    'rows.array_upload'        => {content => "1,2,3"},
    'identifier'               => 'simple',
    'rows.array_upload_format' => 'csv',
    'rows_in_header'           => 0,
  }
)->status_is(200);

my $base = $t->ua->server->url;
$base =~ s[/$][];

$t->get_ok("/array/simple.json")->json_is({
             identifier => 'simple',
         rows_in_header => 0,
                   rows => [ [ 1, 2, 3 ] ],
                    uri => '/array/simple',
                   href => "$base/array/simple.json",
    });

$t->delete_ok("/array/simple");

done_testing();
