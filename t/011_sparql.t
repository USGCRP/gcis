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

my $t = Test::Mojo->new("Tuba");
my $model = RDF::Trine::Model->new;
my $parser = RDF::Trine::Parser->new('turtle');

$t->app->db->dbh->do(q[delete from publication_type where identifier='report']);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('report','report')]);
$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);
$t->post_ok("/report" => form => { identifier => "trees", title => "Tree Report" } )->status_is(200);

my $server_base = $t->ua->server->url;

# Make a new report
my $url = $server_base. 'report/trees.ttl';
$t->get_ok("/report/trees.ttl");

# Get it, parse it into the model
my $ttl = $t->tx->res->body;
# diag $ttl;
$parser->parse_into_model("http://test.data.globalchange.gov", $ttl, $model);

sub uri {
    my $path = shift;
    my $uri = $server_base->clone;
    $uri->path($path);
    return $uri;
}

sub _do_sparql {
    my $model = shift;
    my $sparql = shift;
    
    my $defaults = <<DONE;
PREFIX gcis: <http://data.globalchange.gov/gcis.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
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

# Check that the turtle for the report indicates that the identifier for the report is "/report/trees".
my @rows = _do_sparql($model, <<'SPARQL');
SELECT $x
FROM <http://test.data.globalchange.gov>
WHERE {
    $x rdf:type gcis:Report .
}
SPARQL

is $rows[0]->{x}->value, uri("/report/trees"), "got identifier for report";


# List figures and datasets from which they were derived.
#select ?figure,?dataset FROM <http://data.globalchange.gov>
#where {
# ?figure gcis:hasImage ?img .
# ?img prov:wasDerivedFrom ?dataset
#}

$t->delete_ok("/report/trees" => { Accept => "application/json" })->status_is(200);
done_testing();

