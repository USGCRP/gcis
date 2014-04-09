#!perl

#
# This test creates a report, a chapter, and a finding, and tests that the
# result is valid turtle.
#
use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use tlib;

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

# Check representation of a report.
$t->get_ok("/report/animals.ttl")
    ->status_is(200)
    ->content_like( qr[report/animals] )
    ->content_like( qr[gcis:hasChapter] );

# Try some other formats
$t->get_ok("/report/animals.nt")
    ->status_is(200)
    ->content_like( qr[report/animals] )
    ->content_like( qr[hasChapter] );

$t->get_ok("/report/animals.jsontriples")
    ->status_is(200)
    ->content_like( qr[report/animals] )
    ->content_like( qr[hasChapter] );

$t->get_ok("/report/animals.rdfxml")
    ->status_is(200)
    ->content_like( qr[report/animals] )
    ->content_like( qr[hasChapter] );

$t->get_ok("/report/animals.rdfjson")
    ->status_is(200)
    ->content_like( qr[report/animals] )
    ->content_like( qr[hasChapter] );

$t->get_ok("/report/animals.dot")
    ->status_is(200)
    ->content_like( qr[report/animals] )
    ->content_like( qr[hasChapter] );

$t->get_ok("/report/animals.svg")
    ->status_is(200)
    ->content_like( qr[report/animals] )
    ->content_like( qr[hasChapter] );

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
     => json => { identifier => "gators", title => "fakejournal" } )->status_is(200);

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
        publication_uri => '/report/animals',
        attrs => { end => 'note' } } )->status_is(200);

$t->get_ok("/reference/ref-ref-ref")->status_is(200);

$t->get_ok("/reference/ref-ref-ref.nt")
    ->status_is(200)
    ->content_like( qr[ref-ref-ref] );

# Clean up
$t->delete_ok("/reference/ref-ref-ref")->status_is(200);
$t->delete_ok("/organization/aa")->status_is(200);
$t->delete_ok("/person/$person->{id}")->status_is(200);
$t->delete_ok("/image/be08d5f5-fac1-44a0-9bd3-a3a891c1494a")->status_is(200);
$t->delete_ok("/array/33ac71cb-b34c-4290-962b-bee1125adf7e")->status_is(200);
$t->delete_ok("/report/animals/chapter/alligators/figure/caimans")->status_is(200);
$t->delete_ok("/report/animals/chapter/alligators/table/population")->status_is(200);
$t->delete_ok("/report/animals")->status_is(200);

done_testing();

1;

