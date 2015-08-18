#!perl

#
# This test creates a report, a chapter, and a finding, and tests that the
# result is valid turtle.
#
use open ':std', ':encoding(utf8)';
use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use tlib;
use strict;

chomp(my $found = `which rapper`);
if ($found) {
    chomp(my $version = `rapper --version`);
    diag "using $found (version $version)";
} else {
    plan skip_all => "rapper not found";
}

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
$t->post_ok("/report/animals/chapter" => form => { identifier => "alligators", title => "All about alligators" } )->status_is(200);

# Check representations of a report.
{
    $t->get_ok("/report/animals.ttl")
        ->status_is(200)
        ->content_like( qr[report/animals] )
        ->content_like( qr[gcis:hasChapter] );
    my $body = $t->tx->res->body;
    $t->get_ok("/report/animals" => { Accept => "application/x-turtle" } )
        ->content_is($body);
    $t->get_ok("/report/animals" => { Accept => "text/turtle" } )
        ->content_is($body);
}

# Try some other formats
{
    $t->get_ok("/report/animals.nt")
        ->status_is(200)
        ->content_like( qr[report/animals] )
        ->content_like( qr[hasChapter] );
    my $body = $t->tx->res->body;
    $t->get_ok("/report/animals" => { Accept => "application/n-triples" } )
        ->content_is($body);
    $t->get_ok("/report/animals" => { Accept => "text/n3" } )
        ->content_is($body);
    $t->get_ok("/report/animals" => { Accept => "text/rdf+n3" } )
        ->content_is($body);
}

{
    $t->get_ok("/report/animals.jsontriples")
        ->status_is(200)
        ->content_like( qr[report/animals] )
        ->content_like( qr[hasChapter] );
    my $body = $t->tx->res->body;
    $t->get_ok("/report/animals" => { Accept => "application/ld+json" } )
        ->content_is($body);
}

{
    $t->get_ok("/report/animals.rdfxml")
        ->status_is(200)
        ->content_like( qr[report/animals] )
        ->content_like( qr[hasChapter] );
    my $body = $t->tx->res->body;
    $t->get_ok("/report/animals" => { Accept => "application/rdf+xml" } )
        ->content_is($body);
}

{
    # RDF JSON Alternate Serialization (not recommended)
    $t->get_ok("/report/animals.rdfjson")
        ->status_is(200)
        ->content_like( qr[report/animals] )
        ->content_like( qr[hasChapter] );
    my $body = $t->tx->res->body;
    $t->get_ok("/report/animals" => { Accept => "application/rdf+json" } )
        ->content_is($body);
}

$t->get_ok("/report/animals.dot")
    ->status_is(200)
    ->content_like( qr[report/animals] )
    ->content_like( qr[hasChapter] );

SKIP: {
    skip "no svg on travis version of raptor", 4 if $ENV{TRAVIS};
    $t->get_ok("/report/animals.svg")
        ->status_is(200)
        ->content_like( qr[report/animals] )
        ->content_like( qr[hasChapter] );
}

# Check representation of a chapter.
$t->get_ok("/report/animals/chapter/alligators.ttl")
    ->status_is(200)
    ->content_like( qr[report/animals] );

$t->get_ok("/report/animals/chapter/alligators.nt")
    ->status_is(200)
    ->content_like( qr[report/animals] );

# Figure
$t->post_ok("/report/animals/chapter/alligators/figure" => \%h
     => json => { report_identifier => "animals", chapter_identifier => "alligators", identifier => "caimans", title => "Little alligators" } )->status_is(200);

$t->get_ok("/report/animals/chapter/alligators/figure.json")
    ->status_is(200);

$t->get_ok("/report/animals/chapter/alligators/figure/caimans.nt")
    ->status_is(200)
    ->content_like( qr[Little] );


$t->post_ok("/image" => \%h
     => json => { identifier => "be08d5f5-fac1-44a0-9bd3-a3a891c1494a", title => "fakeimage" } )->status_is(200);

$t->get_ok("/image/be08d5f5-fac1-44a0-9bd3-a3a891c1494a")->status_is(200);

$t->get_ok("/image/be08d5f5-fac1-44a0-9bd3-a3a891c1494a.nt")
    ->status_is(200)
    ->content_like( qr[fakeimage] );

# Table
$t->post_ok("/report/animals/chapter/alligators/table" => \%h
     => json => { report_identifier => "animals", chapter_identifier => "alligators", identifier => "population", title => "Some numbers" } )->status_is(200);

$t->get_ok("/report/animals/chapter/alligators/table.json")
    ->status_is(200);

$t->get_ok("/report/animals/chapter/alligators/table/population.nt")
    ->status_is(200)
    ->content_like( qr[numbers] );

# Array
$t->post_ok("/array" => \%h
     => json => { identifier => "33ac71cb-b34c-4290-962b-bee1125adf7e" } )->status_is(200);

$t->get_ok("/array/33ac71cb-b34c-4290-962b-bee1125adf7e")->status_is(200);

$t->get_ok("/array/33ac71cb-b34c-4290-962b-bee1125adf7e.nt")->status_is(200);

# Finding
$t->post_ok("/report/animals/chapter/alligators/finding" => \%h
     => json => { report_identifier => "animals", chapter_identifier => "alligators", identifier => "amphibians", statement => "Found that they are amphibians." } )->status_is(200);

$t->get_ok("/report/animals/chapter/alligators/finding.json")
    ->status_is(200);

$t->get_ok("/report/animals/chapter/alligators/finding/amphibians.nt")
    ->status_is(200)
    ->content_like( qr[amphibians] );

# Journal
$t->post_ok("/journal" => \%h
     => json => { identifier => "gators", title => "fakejournal", print_issn => '1234-5679' } )->status_is(200);

$t->get_ok("/journal/gators")->status_is(200);

$t->get_ok("/journal/gators.nt")
    ->status_is(200)
    ->content_like( qr[fakejournal] );

# Article
$t->post_ok("/article" => \%h
     => json => { identifier => "gatorade", title => "fakearticle", journal_identifier => 'gators' } )->status_is(200);

$t->get_ok("/article/gatorade")->status_is(200);

$t->get_ok("/article/gatorade.nt")
    ->status_is(200)
    ->content_like( qr[fakearticle] );

# Person
$t->post_ok("/person" => \%h
     => json => { first_name => "Allie", last_name => "Gator" } )->status_is(200);

my $person = $t->tx->res->json;

ok $person->{id}, "Got an id for a person";

$t->get_ok("/person/$person->{id}")->status_is(200);

$t->get_ok("/person/$person->{id}.nt")
    ->status_is(200)
    ->content_like( qr[Allie] );

# Organization
$t->post_ok("/organization" => \%h
     => json => { identifier => "aa", name => "alligators anonymous" } )->status_is(200);

$t->get_ok("/organization/aa")->status_is(200);

$t->get_ok("/organization/aa.nt")
    ->status_is(200)
    ->content_like( qr[anonymous] );

# Reference
$t->post_ok("/reference" => \%h
     => json => { identifier => "ref-ref-ref",
        publication => '/report/animals',
        attrs => { end => 'note' } } )->status_is(200);

$t->get_ok("/reference/ref-ref-ref")->status_is(200);

$t->get_ok("/reference/ref-ref-ref.nt")
    ->status_is(200)
    ->content_like( qr[ref-ref-ref] );

# Dataset
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

$t->get_ok("/dataset/cmip3.ttl")->status_is(200);
$t->get_ok("/dataset/cmip3.nt")->status_is(200);

# Activity

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
$t->get_ok('/activity/teeth-brush.ttl')->status_is(200);
$t->get_ok('/activity/teeth-brush.nt')->status_is(200);

my $project = {
    identifier => "worm",
    name => "Noctural\nanimal",
    description => "curly\nemerges when rains",
    website => "http://nationalzoo.org",
    description_attribution => "http://example.com",
};

$t->post_ok( "/project" => json => $project )->status_is(200);
$t->get_ok('/project/worm.ttl')->status_is(200);
$t->get_ok('/project/worm.nt')->status_is(200);

# Scenario

my $scenario = {
    identifier => "chimp",
    name => "not monkey\nnot organutan",
    description => "primate\nnot really human",
    description_attribution => "http://nationalzoo.org",
};

$t->post_ok( "/scenario" => json => $scenario )->status_is(200);
$t->get_ok('/scenario/chimp.ttl')->status_is(200);
$t->get_ok('/scenario/chimp.nt')->status_is(200);

# Model
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
$t->get_ok('/model/tiger.ttl')->status_is(200);
$t->get_ok('/model/tiger.nt')->status_is(200);


# Model Run
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
$t->get_ok('/model_run/bat.ttl')->status_is(200);
$t->get_ok('/model_run/bat.nt')->status_is(200);

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
$t->delete_ok("/article/gatorade")->status_is(200);
$t->delete_ok("/journal/gators")->status_is(200);
$t->delete_ok("/scenario/chimp")->status_is(200);
$t->delete_ok("/model/tiger")->status_is(200);
$t->delete_ok("/project/worm")->status_is(200);

done_testing();

1;

