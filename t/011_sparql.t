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
    my $sparql = shift;
    
    my $defaults = <<DONE;
PREFIX gcis: <http://data.globalchange.gov/gcis.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX prov: <http://www.w3.org/ns/prov#>
DONE

    my $query = RDF::Query->new("$defaults\n$sparql");
    ok $query, "parsed query" or diag "error parsing\n$defaults\n$sparql\n\n".RDF::Query::error();

    my $results = $query->execute($model);
    my @all;

    while (my $row = $results->next) {
        push @all, $row;
    };
    return @all;
}

sub sparql_ok {
    my ($sparql, $results, $test_name) = @_;
    my @rows = do_sparql($sparql);
    ok @rows == 1, "got one row" or diag $sparql;
    for my $k (keys %$results) {
        ok defined($rows[0]->{$k}), "got value for '$k'" or do {
            ok 0, "missing '$k'";
            next;
        };
        is $rows[0]->{$k}->value,$results->{$k}, $test_name;
    }
}

sub add_to_model {
    my $path = shift;
    $t->get_ok("$path.ttl")->status_is(200);
    my $ttl = $t->tx->res->body;
    eval {
    $parser->parse_into_model("http://test.data.globalchange.gov", $ttl, $model);
    };
    ok !$@ or diag "no errors getting $path : $@\n$ttl";
}

#
# Add a report, chapter, figure, and finding using the API.
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

$t->post_ok(
  "/report/trees/chapter/the-larch/finding" => json => {
    report_identifier  => "trees",
    chapter_identifier => "the-larch",
    identifier         => "larch-trees-are-tall",
    statement          => "Larch trees are tall.",
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
add_to_model('/report/trees');
add_to_model('/report/trees/chapter/the-larch');
add_to_model('/report/trees/chapter/the-larch/figure/tall-green-larch-tree');
add_to_model('/report/trees/chapter/the-larch/finding/larch-trees-are-tall');
add_to_model("/image/$image_identifier");
add_to_model("/dataset/$dataset_identifier");

#
# Okay, now let's do some sparql.
#

# A report has an identifier.
sparql_ok(
  <<'SPARQL',
SELECT $x
FROM <http://test.data.globalchange.gov>
WHERE {
    $x rdf:type gcis:Report .
}
SPARQL
  {
      x => uri("/report/trees")
  }, "report identifier"
);

# A chapter isChapterOf a report.
sparql_ok(
  <<'SPARQL',
SELECT $chapter
FROM <http://test.data.globalchange.gov>
WHERE {
    $report rdf:type gcis:Report .
    $chapter rdf:type gcis:Chapter .
    $chapter gcis:isChapterOf $report .
}
SPARQL
  {chapter => uri("/report/trees/chapter/the-larch")},
  "A chapter isChapterOf a report"
);

# A figure isFigureOf a chapter.
sparql_ok(
  <<'SPARQL',
SELECT $figure
FROM <http://test.data.globalchange.gov>
WHERE {
    $report rdf:type gcis:Report .
    $chapter rdf:type gcis:Chapter .
    $chapter gcis:isChapterOf $report .
    $figure gcis:isFigureOf $chapter
}
SPARQL
  {
    figure => uri("/report/trees/chapter/the-larch/figure/tall-green-larch-tree")
  },
  "A figure isFigureOf a chapter"
);

# A figure hasImage an image
sparql_ok(
  <<'SPARQL',
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
  { image => uri("/image/$image_identifier") }, "A figure hasImage an image"
);

# The image prov:wasDerivedFrom a dataset
sparql_ok(
  <<'SPARQL',
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
  { dataset => uri("/dataset/$dataset_identifier") },
  "An image prov:wasDerivedFrom a dataset"
);

# Find a figure which was derived from a dataset
sparql_ok(<<'SPARQL', 
select $figure $dataset FROM <http://test.data.globalchange.gov>
where {
 $figure gcis:hasImage $img .
 $img prov:wasDerivedFrom $dataset .
}
SPARQL
{
    figure => uri("/report/trees/chapter/the-larch/figure/tall-green-larch-tree"),
    dataset => uri("/dataset/$dataset_identifier"),
}, "Found dataset for figure.");

# Find a chapter finding.
sparql_ok(<<'SPARQL', 
select $finding $report FROM <http://test.data.globalchange.gov>
where {
    $report a gcis:Report .
    $report gcis:hasChapter $chapter .
    $finding gcis:isFindingOf $report .
    $finding gcis:isFindingOf $chapter .
    $finding a gcis:Finding .
}
SPARQL
{
    report => uri("/report/trees"),
    finding => uri("/report/trees/chapter/the-larch/finding/larch-trees-are-tall"),
}, "Found chapter finding in report.");

#
# Ensure that the examples return valid triples
#
$t->get_ok('/examples');
my $examples = $t->tx->res->json;
for my $example (@$examples) {
    my @rows = do_sparql( $example->{code} );
    TODO : {
        local $TODO = "Make tests for examples";
        ok @rows, $example->{desc} or diag "no rows for \n".$example->{code};
    }
}

#
# Cleanup.
#
$t->delete_ok("/report/trees" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/dataset/$dataset_identifier" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/image/$image_identifier" => { Accept => "application/json" })->status_is(200);

done_testing();

