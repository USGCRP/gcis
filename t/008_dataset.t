#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use v5.14;

my $t = Test::Mojo->new("Tuba");
$t->app->db->dbh->do(q[delete from publication_type where identifier='dataset']);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('dataset','dataset')]);

$t->ua->max_redirects(1);

my $base = $t->ua->server->url;
$base =~ s[/$][];

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

$dataset->{href} = "$base/dataset/my-temps.json";
$dataset->{uri} = "/dataset/my-temps";
$dataset->{instrument_measurements} = [];

$t->get_ok( "/dataset/my-temps.json" )->status_is(200)->json_is($dataset);

# A platform.
my $platform = {
  identifier  => "house",
  name        => "house with thermometers on the side",
  description => "our house, in the middle of our street",
  platform_type_identifier => undef,
  url         => undef,
  description_attribution => undef,
};
$t->post_ok( "/platform" => json => $platform )->status_is(200);
$platform->{uri} = "/platform/house";
$platform->{href} = "$base/platform/house.json";
$t->get_ok( "/platform/house.json" )->status_is(200)->json_is($platform);

# An instrument.
my $instrument = {
  identifier => "mercury-in-glass-thermometer",
  name       => "Mercury in glass thermometer",
  description => "This type of thermometer was invented in 1714 by Daniel Fahrenheit.",
};
$t->post_ok( "/instrument" => json => $instrument )->status_is(200);
$instrument->{uri} = "/instrument/mercury-in-glass-thermometer";
$instrument->{href} = "$base/instrument/mercury-in-glass-thermometer.json";
$t->get_ok("/instrument/mercury-in-glass-thermometer.json")->status_is(200)->json_is($instrument);

# One of these instruments is on the house.
$t->post_ok( "/platform/rel/house", json => {
        add => { instrument_identifier => "mercury-in-glass-thermometer",
                 location => "on the north side, next to the window" }
        }
);

# Get the "instrument instance".
$t->get_ok( "/platform/house/instrument/mercury-in-glass-thermometer.json" )->status_is(200)
    ->json_is( { instrument_identifier => "mercury-in-glass-thermometer",
                 platform_identifier => "house",
                 location => "on the north side, next to the window",
                 uri => "/platform/house/instrument/mercury-in-glass-thermometer",
                 href => "$base/platform/house/instrument/mercury-in-glass-thermometer.json",

             } );

# Reading the thermometer on the house generates the dataset.
$t->post_ok("/dataset/rel/my-temps", json => {
        add_instrument_measurement => {
            platform_identifier => "house",
            instrument_identifier => "mercury-in-glass-thermometer",
        }
    });

$dataset->{instrument_measurements} = [
     {
       'dataset_identifier' => 'my-temps',
       'instrument_identifier' => 'mercury-in-glass-thermometer',
       'platform_identifier' => 'house'
     }
   ];
$t->get_ok("/dataset/my-temps.json")->json_is($dataset);

# clean up
$t->delete_ok('/instrument/mercury-in-glass-thermometer');
$t->delete_ok('/dataset/my-temps');
$t->delete_ok('/platform/house');

done_testing();

