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
PREFIX owl:  <http://www.w3.org/2002/07/owl#>
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

my $instrument_identifier = 'leica-dlux';
my $platform_identifier = 'tripod';
# The leica-dlux on the tripod was used to create the dataset.
$t->post_ok( "/platform" => json => {
        identifier => $platform_identifier,
        name => "This is a tripod used to mount instruments and collect data."
    });
$t->post_ok( "/instrument" => json => {
        identifier => $instrument_identifier,
        name => "This is a sensitive camera used to collect data."
    });
$t->post_ok( "/platform/rel/$platform_identifier" => json => {
        add => { instrument_identifier => $instrument_identifier },
        location => "top"
    }
);
$t->post_ok("/dataset/rel/$dataset_identifier" => json => {
        add_instrument_measurement => {
            platform_identifier => $platform_identifier,
            instrument_identifier => $instrument_identifier,
        }
    });

# Add a dbpedia lexicon
$t->post_ok( "/lexicon", json => { identifier => 'dbpedia' } )->status_is(200);

# Also add a dbpedia owl:sameAs
my $dbpedia_platform_identifier = "Three-pod";
$t->post_ok( "/lexicon/dbpedia/term/new" => json => {
        term => $dbpedia_platform_identifier, context => 'resource', gcid => "/platform/$platform_identifier" } );

# add a role
my $role_identifier = "lead_author";
$t->post_ok( "/role_type" => json => { identifier => $role_identifier, label => "Lead Author" } )->status_is(200);

# add a person
my $person_identifier = "101";
$t->post_ok( "/person" => json => { id => $person_identifier, first_name  => "John", last_name   => "Doe", } )->status_is(200);

# add an organization
my $org_identifier = "acme";
$t->post_ok(
  "/organization" => json => {
    identifier  => $org_identifier,
    name        => "Acme Inc.",
  }
)->status_is(200);

# The chapter was attributed to that author
$t->post_ok("/report/trees/chapter/contributors/the-larch" => json =>
    { person_id => $person_identifier, organization_identifier => $org_identifier, role => $role_identifier })->status_is(200);

#
# Parse them into the model
#
add_to_model('/report/trees');
add_to_model('/report/trees/chapter/the-larch');
add_to_model('/report/trees/chapter/the-larch/figure/tall-green-larch-tree');
add_to_model('/report/trees/chapter/the-larch/finding/larch-trees-are-tall');
add_to_model("/image/$image_identifier");
add_to_model("/dataset/$dataset_identifier");
add_to_model("/platform/$platform_identifier");
add_to_model("/instrument/$instrument_identifier");
add_to_model("/role_type/$role_identifier");
add_to_model("/person/$person_identifier");
add_to_model("/organization/$org_identifier");
add_to_model("/report/trees/chapter/contributors/the-larch");

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

# Ensure that the dataset is associated with the instrument instance.
my $dataset_uri = uri("/dataset/$dataset_identifier");
sparql_ok(<<SPARQL,
select ?instance FROM <http://test.data.globalchange.gov>
where {
    <$dataset_uri> prov:wasAttributedTo ?instance .
}
SPARQL
{
    instance => uri("/platform/$platform_identifier/instrument/$instrument_identifier")
}, "Found instrument instance for dataset");

# Ensure that the platform is the same as the dbpedia platform
my $platform_uri = uri("/platform/$platform_identifier");
sparql_ok(<<SPARQL,
select ?dbp FROM <http://test.data.globalchange.gov>
where {
    <$platform_uri> owl:sameAs ?dbp .
}
SPARQL
{
    dbp => "http://dbpedia.org/resource/$dbpedia_platform_identifier"
}, "Found dbpedia platform sameAs this platform");


#
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

# The chapter was attributed to a person
sparql_ok(
  <<'SPARQL',
SELECT ?author ?role
FROM <http://test.data.globalchange.gov>
WHERE {
    ?report rdf:type gcis:Report .
    ?chapter rdf:type gcis:Chapter .
    ?chapter gcis:isChapterOf ?report .
    ?chapter prov:qualifiedAttribution ?attribution .
    ?attribution prov:hadRole ?role .
    ?attribution prov:agent ?author .
    ?author rdf:type foaf:Person.
}
SPARQL
  { author => uri("/person/$person_identifier"),
    role => uri("/role_type/$role_identifier")
  }, "The chapter was attributed to a person"
);

#
# Cleanup.
#
$t->delete_ok("/report/trees" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/dataset/$dataset_identifier" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/image/$image_identifier" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/platform/$platform_identifier");
$t->delete_ok("/instrument/$instrument_identifier");

done_testing();

