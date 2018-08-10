#!perl

#
# This is like 005_turtle.t, but uses RDF::Trine, not rapper
#
use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use tlib;
use strict;

use_ok "Tuba";
my $t = Test::Mojo->new("Tuba");

my %h = (Accept => 'application/json');

$t->app->db->dbh->do(q[delete from publication_type where identifier='report']);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('report','report')]);

$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

# Create a report called animals
$t->post_ok("/report" => form => { identifier => "animals", title => "Animals" } )->status_is(200);

# Create a chapter called alligators
$t->post_ok("/report/animals/chapter" => form =>
    {identifier => "alligators", title => "All about alligators"})
  ->status_is(200);
$t->post_ok(
  "/report/animals/chapter/alligators/figure" => \%h => json => {
    report_identifier  => "animals",
    chapter_identifier => "alligators",
    identifier         => "caimans",
    title              => "Little alligators"
  }
)->status_is(200);
$t->post_ok(
  "/image" => \%h => json => {
    identifier => "be08d5f5-fac1-44a0-9bd3-a3a891c1494a",
    title      => "fakeimage"
  }
)->status_is(200);
$t->post_ok(
  "/report/animals/chapter/alligators/table" => \%h => json => {
    report_identifier  => "animals",
    chapter_identifier => "alligators",
    identifier         => "population",
    title              => "Some numbers"
  }
)->status_is(200);
$t->post_ok("/array" => \%h => json =>
    {identifier => "33ac71cb-b34c-4290-962b-bee1125adf7e"})->status_is(200);
$t->post_ok(
  "/report/animals/chapter/alligators/finding" => \%h => json => {
    report_identifier  => "animals",
    chapter_identifier => "alligators",
    identifier         => "amphibians",
    statement          => "Found that they are amphibians."
  }
)->status_is(200);
$t->post_ok("/journal" => \%h => json =>
    {identifier => "gators", title => "fakejournal", print_issn => "1234-5679"})->status_is(200);
$t->post_ok(
  "/article" => \%h => json => {
    identifier         => "gatorade",
    title              => "fakearticle",
    journal_identifier => 'gators'
  }
)->status_is(200);
$t->post_ok(
  "/person" => \%h => json => {first_name => "Allie", last_name => "Gator"})
  ->status_is(200);
my $person = $t->tx->res->json;
ok $person->{id}, "Got an id for a person";
$t->post_ok("/organization" => \%h => json =>
    {identifier => "aa", name => "alligators anonymous"})->status_is(200);
$t->post_ok(
  "/reference" => \%h => json => {
    identifier   => "ref-ref-ref",
    publication  => '/report/animals',
    attrs        => {end => 'note'}
  }
)->status_is(200);
my $dataset = {
    identifier => "cmip3",
    name       => "readings\n from my thermometer",
    type       => undef,
    version    => "N/A",
    description => "These are
    some readings from the\n\r
    \n\r\n thermometer outside my house",
    native_id        => "Unknown",
    publication_year => "2007",
    access_dt        => "2013-01-24T00:00:00",
    release_dt       => undef,
    attributes       => "2-meter surface temperature and others as listed at: http://www-pcmdi.llnl.gov/ipcc/standard_output.html",
    url              => "http://example.com/my-temps",
    data_qualifier   => "taken\nonly on tuesdays",
    scale            => undef,
    spatial_ref_sys  => "wgs84",
    cite_metadata    => "a big\nmetadata document\nwith returns",
    scope            => "local",
    spatial_extent   => "maximum_latitude: 90; minimum_latitude: -90; maximum_longitude: 180; minimum_longitude: -180;",
    temporal_extent  => "1850-01-01T00:00:00 2300-12-31T23:59:59",
    vertical_extent  => "high",
    processing_level => undef,
    spatial_res      => "point",
    doi              => "10.123/123",
    lat_min          => undef,
    lon_min          => undef,
    lat_max          => undef,
    lon_max          => undef,
    start_time       => "2010-01-22T00:00:00",
    end_time         => "2011-01-29T00:00:00",
    variables        => "x y z",
};

$t->post_ok( "/dataset" => json => $dataset )->status_is(200);

my $activity = {
    identifier => "teeth-brush",
    data_usage => "a little\ntooth paste",
    methodology => "back and forth\nside to side",
    start_time => '2001-01-01',
    end_time => '2001-01-02',
    duration => '1 day',
    computing_environment => "sink\nand faucet",
    output_artifacts => "plaque\non teeth",
    software => "crest\nor tom's",
    visualization_software => "mirror\nmirror on the wall",
    notes => "every day\n is a good to brush your teeth",
};

$t->post_ok( "/activity" => json => $activity )->status_is(200);

my $spatial_extent = do {
    local $/ = undef;
    open my $fh, "<", "./t/va_spatial_extent.geojson"
        or die "could not open va_spatial_extent.geojson: $!";
    <$fh>;
};

my $new_activity = {
    identifier => "temperature_in_virginia_in_2000",
    computing_environment => "Ubuntu Trusty, R 3.5.1",
    software => "my-r-script.r",
    visualization_software => "that-one-vis-program v1.0.3",
    activity_duration => '1 hours',
    source_access_date => '2018-01-01',
    interim_artifacts => 'va_data_subset.csv',
    output_artifacts => "temperature_in_va_2000.png",
    source_modifications => "Subset to the date 2000-01-01 and the region of Virginia",
    modified_source_location => "github.com/example_scientist/usgcrp_work/va_data_subset.csv",
    methodology => "subset the US dataset via the temporal and spatial restrictions\nrun the r script on it\nput it into that one vis program\noutput the graph",
    visualization_methodology => "Used the viz program and did art things",
    methodology_citation => "Author, A et al This is a citation to a standard documented methodology",
    methodology_contact => "Author, A",
    database_variables => "Temperature",
    start_time => '2000-01-01',
    end_time => '2000-01-01',
    spatial_extent => $spatial_extent,
};

$t->post_ok( "/activity" => json => $new_activity )->status_is(200);

my $project = {
    identifier => "worm",
    name => "Noctural\nanimal",
    description => "curly\nemerges when rains",
    website => "http://nationalzoo.org",
    description_attribution => "http://example.com",
};

$t->post_ok( "/project" => json => $project )->status_is(200);

my $scenario = {
    identifier => "chimp",
    name => "not monkey\nnot organutan",
    description => "primate\nnot really human",
    description_attribution => "http://nationalzoo.org",
};

$t->post_ok( "/scenario" => json => $scenario )->status_is(200);
my $model = {
    identifier => "tiger",
    name => "instance of\ncat",
    version => "tiger",
    description => "oh my lions\nbears",
    description_attribution => "http://nationalzoo.org",
    reference_url => "http://example.com",
    project_identifier => "worm",
};

$t->post_ok( "/model" => json => $model )->status_is(200);
my $model_run = {
    identifier => "bat",
    doi => "10.999999/9998",
    spatial_resolution => "1 degree",
    range_start => "2021-01-01T00:00:00",
    range_end => "2050-01-01T00:00:00",
    time_resolution => "15 minutes",
    scenario_identifier => "chimp",
    model_identifier => "tiger",
    activity_identifier => "teeth-brush",
    project_identifier => "worm",  
    sequence => "1",
    sequence_description => "sequence is\n as follows",

};

$t->post_ok( "/model_run" => json => $model_run )->status_is(200);

$t->get_ok("/report/animals.ttl")->status_is(200)->turtle_ok;
$t->get_ok("/report/animals/chapter/alligators.ttl")->turtle_ok;
$t->get_ok("/report/animals/chapter/alligators/figure.ttl")->turtle_ok;
$t->get_ok("/image/be08d5f5-fac1-44a0-9bd3-a3a891c1494a.ttl")->turtle_ok;
$t->get_ok("/report/animals/chapter/alligators/table/population.ttl")->turtle_ok;
$t->get_ok("/array/33ac71cb-b34c-4290-962b-bee1125adf7e.ttl")->turtle_ok;
$t->get_ok("/report/animals/chapter/alligators/finding/amphibians.ttl")->turtle_ok;
$t->get_ok("/journal/gators.ttl")->turtle_ok;
$t->get_ok("/article/gatorade.ttl")->turtle_ok;
$t->get_ok("/person/$person->{id}.ttl")->turtle_ok;
$t->get_ok("/organization/aa.ttl")->turtle_ok;
$t->get_ok("/reference/ref-ref-ref.ttl")->turtle_ok;
$t->get_ok("/dataset/cmip3.ttl")->turtle_ok;
$t->get_ok('/activity/teeth-brush.ttl')->turtle_ok;
$t->get_ok('/activity/temperature_in_virginia_in_2000.ttl')->turtle_ok;
$t->get_ok('/project/worm.ttl')->turtle_ok;
$t->get_ok('/scenario/chimp.ttl')->turtle_ok;
$t->get_ok('/model/tiger.ttl')->turtle_ok;
$t->get_ok('/model_run/bat.ttl')->turtle_ok;

# Clean up
$t->delete_ok("/reference/ref-ref-ref")->status_is(200);
$t->delete_ok("/organization/aa")->status_is(200);
$t->delete_ok("/person/$person->{id}")->status_is(200);
$t->delete_ok("/image/be08d5f5-fac1-44a0-9bd3-a3a891c1494a")->status_is(200);
$t->delete_ok("/array/33ac71cb-b34c-4290-962b-bee1125adf7e")->status_is(200);
$t->delete_ok("/report/animals/chapter/alligators/figure/caimans")->status_is(200);
$t->delete_ok("/report/animals/chapter/alligators/table/population")->status_is(200);
$t->delete_ok("/report/animals")->status_is(200);
$t->delete_ok("/dataset/cmip3")->status_is(200);
$t->delete_ok("/model_run/bat")->status_is(200);
$t->delete_ok("/activity/teeth-brush")->status_is(200);
$t->delete_ok("/activity/temperature_in_virginia_in_2000")->status_is(200);
$t->delete_ok("/article/gatorade")->status_is(200);
$t->delete_ok("/journal/gators")->status_is(200);
$t->delete_ok("/scenario/chimp")->status_is(200);
$t->delete_ok("/model/tiger")->status_is(200);
$t->delete_ok("/project/worm")->status_is(200);

done_testing();

1;

