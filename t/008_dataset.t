#!perl

use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use v5.14;

my $t = Test::Mojo->new("Tuba");
$t->app->db->dbh->do(q[delete from publication_type where identifier='dataset']);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('dataset','dataset')]);

$t->ua->max_redirects(1);

my $base = $t->ua->server->url;

$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

my $dataset = {
    identifier => "my-temps",
    name       => "readings from my thermometer",
    type       => "observational",
    version    => 12,
    description => "These are some readings from the thermometer outside my house",
    native_id        => "my-12345",
    publication_year => "2014",
    access_dt        => "2013-01-24T00:00:00",
    release_dt       => "2013-01-24T00:00:00",
    attributes       => "foo bar baz",
    url              => "http://example.com/my-temps",
    data_qualifier   => "taken only on tuesdays",
    scale            => "1-1",
    spatial_ref_sys  => "wgs84",
    cite_metadata    => "yes",
    scope            => "local",
    spatial_extent   => "my house",
    temporal_extent  => "tuesdays feb 2014",
    vertical_extent  => "high",
    processing_level => "3",
    spatial_res      => "point",
    doi              => "10.123/123",
    lat_min          => 0,
    lon_min          => 0,
    lat_max          => 0,
    lon_max          => 0,
    start_time       => "2010-01-22T00:00:00",
    end_time         => "2011-01-29T00:00:00",
    variables        => "x y z",
};


$t->post_ok( "/dataset" => json => $dataset )->status_is(200);

$dataset->{href} = "${base}dataset/my-temps.json";
$dataset->{uri} = "/dataset/my-temps";

$t->get_ok( "/dataset/my-temps.json" )->status_is(200)->json_is($dataset);

done_testing();

