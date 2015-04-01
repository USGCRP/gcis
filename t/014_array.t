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

# insert multiple row data via CSV
$t->post_ok(
  "/array" => form => {
    'rows.array_upload'        => {content => "header_1,header_2,header_3,header_4\n1,2,3,4"},
    'identifier'               => 'multirow-csv',
    'rows.array_upload_format' => 'csv',
    'rows_in_header'           => 1,
  }
)->status_is(200);

$t->get_ok("/array/multirow-csv.json")->json_is({
             identifier => 'multirow-csv',
         rows_in_header => 1,
                   rows => [ [ "header_1", "header_2", "header_3", "header_4" ],
                             [ 1, 2, 3, 4 ] ],
                    uri => '/array/multirow-csv',
                   href => "$base/array/multirow-csv.json",
    });

# update multiple row data via editable grid
$t->post_ok(
  "/array/multirow-csv" => form => {
    'rows.array_upload'        => {content => ""},
    'grid_array'               => '[["new_header_1","new_header_2"],["sub_header_1","sub_header_2"],["foo","bar"]]',
    'identifier'               => 'multirow-csv',
    'rows_in_header'           => 2,
  }
)->status_is(200);

$t->get_ok("/array/multirow-csv.json")->json_is({
             identifier => 'multirow-csv',
         rows_in_header => 2,
                   rows => [ [ "new_header_1", "new_header_2" ],
                             [ "sub_header_1", "sub_header_2" ],
                             [ "foo", "bar" ] ],
                    uri => '/array/multirow-csv',
                   href => "$base/array/multirow-csv.json",
    });

$t->delete_ok("/array/multirow-csv");

done_testing();
