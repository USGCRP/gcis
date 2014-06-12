#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use RDF::Trine qw( statement iri literal );
use RDF::Trine::Parser;
use RDF::Query;
use strict;

#
# Create a report, then pull the turtle into an in-memory triple store
# then run some SPARQL queries to ensure that the turtle makes sense.
#

use_ok "Tuba";

#
# Various initializations
#
my $t = Test::Mojo->new("Tuba");
my $model = RDF::Trine::Model->new;
my $parser = RDF::Trine::Parser->new('turtle');
my $server_base = $t->ua->server->url;
$t->app->db->dbh->do(q[delete from publication_type]);
for my $table (qw/figure finding chapter report dataset image/) {
    $t->app->db->dbh->do(qq[insert into publication_type ("table",identifier) values ('$table','$table')]);
}
$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

#
# Some handy helpers
#
sub uri {
    my $path = shift;
    my $uri = $server_base->clone;
    $uri->path($path);
    return $uri;
}

sub do_sparql {
    my $model = shift;
    my $sparql = shift;
    
    my $defaults = <<DONE;
PREFIX gcis: <http://data.globalchange.gov/gcis.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX prov: <http://www.w3.org/ns/prov#>
DONE

    my $query = RDF::Query->new("$defaults\n$sparql");
    ok $query, "parsed query" or diag RDF::Query::error();

    my $results = $query->execute($model);
    my @all;

    while (my $row = $results->next) {
        push @all, $row;
    };
    return @all;
}

sub add_to_model {
    my $model = shift;
    my $path = shift;
    $t->get_ok("$path.ttl")->status_is(200);
    my $ttl = $t->tx->res->body;
    eval {
    $parser->parse_into_model("http://test.data.globalchange.gov", $ttl, $model);
    };
    ok !$@ or diag "no errors getting $path : $@\n$ttl";
}

#
# Add a report, chapter and figure, using the API
#
$t->post_ok(
  "/report" => form => {
    identifier => "trees",
    title => "How to Recognise Different Types of Trees From Quite a Long Way Away"
  })->status_is(200);

$t->post_ok(
  "/report/trees/chapter" => json => {
    report_identifier => "trees",
    identifier        => "the-larch",
    title             => "Number one : The Larch",
  })->status_is(200);

$t->post_ok(
  "/report/trees/chapter/the-larch/figure" => json => {
    report_identifier  => "trees",
    chapter_identifier => "the-larch",
    identifier         => "tall-green-larch-tree",
    title              => "This is a larch tree.",
    ordinal            => 1,
  })->status_is(200);

my $image_identifier = "99285d0f-ea9b-4bf2-80aa-3b968420c8b0";
$t->post_ok(
  "/image" => json => {
    identifier => $image_identifier,
    title => "Larch leaves",
  }
)->status_is(200);
$t->post_ok("/report/trees/chapter/the-larch/figure/rel/tall-green-larch-tree" => json =>
    {add_image_identifier => $image_identifier })
  ->status_is(200);

my $dataset_identifier = "r12345-larch-leaves-dataset";
$t->post_ok(
  "/dataset" => json => {
    identifier => $dataset_identifier,
  }
)->status_is(200);

# The larch image wasDerived from that dataset.
$t->post_ok(
  "/image/prov/$image_identifier" => json => {
    parent_uri => "/dataset/r12345-larch-leaves-dataset",
    parent_rel => "prov:wasDerivedFrom",
    note       => "Number one : the larch, was derived from this dataset",
  }
)->status_is(200);



#
# Parse them into the model
#
add_to_model($model, '/report/trees');
add_to_model($model, '/report/trees/chapter/the-larch');
add_to_model($model, '/report/trees/chapter/the-larch/figure/tall-green-larch-tree');
add_to_model($model, "/image/$image_identifier");
add_to_model($model, "/dataset/$dataset_identifier");

#
# Okay, now let's do some sparql.
#

# A report has an identifier.
my @rows;
@rows = do_sparql($model, <<'SPARQL');
SELECT $x
FROM <http://test.data.globalchange.gov>
WHERE {
    $x rdf:type gcis:Report .
}
SPARQL
is $rows[0]->{x}->value, uri("/report/trees"), "got identifier for report";

# A chapter isChapterOf a report.
@rows = do_sparql($model, <<'SPARQL');
SELECT $chapter
FROM <http://test.data.globalchange.gov>
WHERE {
    $report rdf:type gcis:Report .
    $chapter rdf:type gcis:Chapter .
    $chapter gcis:isChapterOf $report .
}
SPARQL
ok @rows==1, 'got one row';
is $rows[0]->{chapter}->value, uri("/report/trees/chapter/the-larch"), "A chapter isChapterOf a report";

# A figure isFigureOf a chapter.
@rows = do_sparql($model, <<'SPARQL');
SELECT $figure
FROM <http://test.data.globalchange.gov>
WHERE {
    $report rdf:type gcis:Report .
    $chapter rdf:type gcis:Chapter .
    $chapter gcis:isChapterOf $report .
    $figure gcis:isFigureOf $chapter
}
SPARQL
ok @rows==1, 'got one row';
is $rows[0]->{figure}->value, uri("/report/trees/chapter/the-larch/figure/tall-green-larch-tree"), "A figure isFigureOf a chapter";

# A figure hasImage an image
@rows = do_sparql($model, <<'SPARQL');
SELECT $image
FROM <http://test.data.globalchange.gov>
WHERE {
    $report rdf:type gcis:Report .
    $chapter rdf:type gcis:Chapter .
    $chapter gcis:isChapterOf $report .
    $figure gcis:isFigureOf $chapter .
    $figure gcis:hasImage $image .
}
SPARQL
ok @rows==1, 'got one row';
is $rows[0]->{image}->value, uri("/image/$image_identifier"), "A figure hasImage an image";

# The image prov:wasDerivedFrom a dataset
# A figure hasImage an image
@rows = do_sparql($model, <<'SPARQL');
SELECT $dataset
FROM <http://test.data.globalchange.gov>
WHERE {
    $report rdf:type gcis:Report .
    $chapter rdf:type gcis:Chapter .
    $chapter gcis:isChapterOf $report .
    $figure gcis:isFigureOf $chapter .
    $figure gcis:hasImage $image .
    $image prov:wasDerivedFrom $dataset .
}
SPARQL
ok @rows==1, 'got one row';
is @rows && $rows[0]->{dataset}->value, uri("/dataset/$dataset_identifier"), "An image prov:wasDerivedFrom a dataset";

# Find a figure which was derived from a dataset
@rows = do_sparql($model, <<'SPARQL');
select $figure $dataset FROM <http://test.data.globalchange.gov>
where {
 $figure gcis:hasImage $img .
 $img prov:wasDerivedFrom $dataset .
}
SPARQL
ok @rows==1, 'got one dataset for an image + figure';
is @rows && $rows[0]->{figure}->value, uri("/report/trees/chapter/the-larch/figure/tall-green-larch-tree"), "Found figure for dataset.";
is @rows && $rows[0]->{dataset}->value, uri("/dataset/$dataset_identifier"), "Found dataset for figure.";

#
# Cleanup.
#
$t->delete_ok("/report/trees" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/dataset/$dataset_identifier" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/image/$image_identifier" => { Accept => "application/json" })->status_is(200);
done_testing();



