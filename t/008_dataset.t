#!perl

use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use v5.14;

my $t = Test::Mojo->new("Tuba");
$t->app->db->dbh->do(q[delete from publication_type where identifier='dataset']);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('dataset','dataset')]);

$t->ua->max_redirects(1);

my $base = $t->ua->app_url;

$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

my $dataset = {
    identifier => "my-temps",
    name       => "readings from my thermometer",
    type       => "observational",
    version    => 12,
    description => "These are some readings from the thermometer outside my house",
    native_id        => "my-12345",
    publication_dt   => "2014-01-23T00:00:00",
    access_dt        => "2013-01-24T00:00:00",
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
};


$t->post_ok( "/dataset" => json => $dataset )->status_is(200);

$dataset->{href} = "${base}dataset/my-temps.json";
$dataset->{uri} = "/dataset/my-temps";

$t->get_ok( "/dataset/my-temps.json" )->status_is(200)->json_is($dataset);

done_testing();

