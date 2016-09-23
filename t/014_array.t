#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use strict;
use warnings;

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");

$t->app->db->dbh->do(q[delete from publication_type]);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('table','table')]);
my $base = $t->ua->server->url;
$base =~ s[/$][];
$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

$t->post_ok("/report" => json => {identifier => "vegetables", title => "Veggies"})->status_is(200);

$t->post_ok("/report/vegetables/table" =>
  { Accept => "application/json"} => json => {
      identifier => 'veggietable',
      report_identifier => 'vegetables',
      title => 'veggie table',
      ordinal => 1,
      caption => 'numbers of veggies',
      url => 'http://example.com/veggies'
})->status_is(200);

$t->post_ok(
  "/array" => form => {
    'rows.array_upload'        => {content => "1,2,3"},
    'identifier'               => 'simple',
    'rows.array_upload_format' => 'csv',
    'rows_in_header'           => 0,
  }
)->status_is(200);

$t->post_ok(
  "/report/vegetables/table/rel/veggietable" => json =>
  { add_array_identifier => "simple" }
)->status_is(200);

$t->get_ok("/report/vegetables/table/veggietable.json")->status_is(200)
  ->json_is(
 {
   'arrays' => [
     {
       'identifier' => 'simple',
       'rows' => [ [ '1', '2', '3' ] ],
       'rows_in_header' => 0
     }
   ],
   'caption' => 'numbers of veggies',
   'chapter_identifier' => undef,
   'contributors' => [],
   'files' => [],
   'href' => "$base/report/vegetables/table/veggietable.json",
   'identifier' => 'veggietable',
   'ordinal' => 1,
   'parents' => [],
   'references' => [],
   'cited_by' => [],
   'report_identifier' => 'vegetables',
   'title' => 'veggie table',
   'uri' => '/report/vegetables/table/veggietable',
   'url' => 'http://example.com/veggies',
   'display_name' => 'veggie table',
   'type' => 'table',
 }
);

#diag explain $t->tx->res->json;

$t->get_ok("/array/simple.json")->json_is({
             identifier => 'simple',
         rows_in_header => 0,
                   rows => [ [ 1, 2, 3 ] ],
                    uri => '/array/simple',
                   href => "$base/array/simple.json",
                   tables => [
                     {
                       'caption' => 'numbers of veggies',
                       'chapter_identifier' => undef,
                       'identifier' => 'veggietable',
                       'ordinal' => 1,
                       'report_identifier' => 'vegetables',
                       'title' => 'veggie table',
                       'url' => 'http://example.com/veggies'
                     }
                   ],
                   cited_by => [],
           display_name => 'simple',
                   type => 'array',
                parents => [],
    });

#diag explain $t->tx->res->json;

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
                   cited_by => [],
                   type => 'array',
                   display_name => 'multirow-csv',
                   parents => [],
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
                   cited_by => [],
                   type => 'array',
                   display_name => 'multirow-csv',
                   parents => [], 
    });

$t->delete_ok("/array/multirow-csv");
$t->delete_ok("/report/vegetables/table/veggietable");
$t->delete_ok("/report/vegetables");

done_testing();
