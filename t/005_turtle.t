#!perl

#
# This test creates a report, a chapter, and a finding, and tests that the
# result is valid turtle.
#
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");

$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

# Create a report called animals
$t->post_ok("/report" => form => { identifier => "animals" } )->status_is(200);

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

# TODO : figure, image, finding, journal, article, reference

# Clean up
$t->delete_ok("/report/animals")->status_is(200);

done_testing();

1;

