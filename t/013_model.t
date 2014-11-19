use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use v5.14;

my $t = Test::Mojo->new("Tuba");
$t->app->db->dbh->do(q[delete from publication_type where identifier='model']);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('model','model')]);

$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

my $base = $t->ua->server->url;
$base =~ s[/$][];

# Project
my %project = (
    identifier => 'cmip12',
    name => 'Crustacean Mustard Ingestion Project Phase 12',
    description => "In this project we investigate the effects of mustard on crustaceans.",
    description_attribution => "http://wikipedia.com/cmip12",
    website => "http://crustacean12.com",
);
$t->post_ok("/project" => json => \%project )->status_is(200);
$t->get_ok("/project/cmip12.json")->status_is(200)
  ->json_is( { %project,
    uri       => "/project/cmip12",
    href => "$base/project/cmip12.json" });
$t->get_ok("/project")->status_is(200)->content_like(qr/cmip12/);

# Model
my %model = (
    identifier => 'ccsm3',
    project_identifier => 'cmip12',
    name => 'Community Climate System Model, version 3.0 (CCSM3)',
    reference_url => 'http://www-pcmdi.llnl.gov/ipcc/model_documentation/CCSM3.htm',
    website => 'http://www2.cesm.ucar.edu/',
    version => 3,
    description => 'The Community Climate Model (CCM) was created by NCAR in 1983.',
    description_attribution => 'http://www2.cesm.ucar.edu/about',
);
$t->post_ok("/model" => json => \%model )->status_is(200);
$t->get_ok("/model/ccsm3.json")->status_is(200)
  ->json_is( { %model,
    uri       => "/model/ccsm3",
    href => "$base/model/ccsm3.json" });
$t->get_ok("/model")->status_is(200)->content_like(qr/ccsm3/);

# Scenario
my %scenario = (
    identifier => "sres_a2",
    name => "Some Rain Eludes Spain Arrrrr 2",
    description => "While some rain fails mainly in the plains, some rain eludes Spain",
    description_attribution => 'http://google.com',
);
$t->post_ok("/scenario" => json => \%scenario )->status_is(200);
$t->get_ok("/scenario/sres_a2.json")->status_is(200)
  ->json_is( { %scenario,
    uri       => "/scenario/sres_a2",
    href => "$base/scenario/sres_a2.json" });
$t->get_ok("/scenario")->status_is(200)->content_like(qr[sres_a2]);

# Model run
my %run = (
    identifier => '012345',
    activity_identifier => undef,
    project_identifier => 'cmip12',
    model_identifier => 'ccsm3',
    scenario_identifier => 'sres_a2',
    range_start => '2000-01-01T00:00:00',
    range_end => '2020-01-01T00:00:00',
    spatial_resolution => '1 mile',
    time_resolution => "10 minutes",
    doi => undef,
    sequence => 1,
    sequence_description => undef,
);
$t->post_ok("/model_run" => json => \%run )->status_is(200);
$t->get_ok("/model_run/012345.json")->status_is(200)
    ->json_is( { %run,
        uri => "/model_run/012345",
        href => "$base/model_run/012345.json",
        sequence => 1,
    });
$t->get_ok("/model_run")->status_is(200)->content_like(qr[012345]);
$t->get_ok("/model/ccsm3/run")->status_is(200)->content_like(qr[012345]);
$t->get_ok("/model_run/ccsm3/sres_a2/2000-01-01/2020-01-01/1 mile/1.json")
  ->status_is(200)->content_like(qr/012345/);

$t->delete_ok("/model_run/012345")->status_is(200);
$t->delete_ok("/scenario/sres_a2")->status_is(200);
$t->delete_ok("/model/ccsm3")->status_is(200);
$t->delete_ok("/project/cmip12")->status_is(200);
$t->get_ok("/project/cmip12.json")->status_is(404);

done_testing();

