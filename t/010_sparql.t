use 5.010;
use strict;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;
use RDF::Trine qw( statement iri literal );
use RDF::Trine::Parser;
use RDF::Query;

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

my $url = $server_base. 'report/trees.ttl';

$t->get_ok("/report/trees.ttl");

my $ttl = $t->tx->res->body;

# diag $ttl;

$parser->parse_into_model("http://test.data.globalchange.gov", $ttl, $model);

my $query = RDF::Query->new(<<'SPARQL') or die RDF::Query::error();
PREFIX gcis: <http://data.globalchange.gov/gcis.owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT $x
FROM <http://test.data.globalchange.gov>
WHERE {
    $x rdf:type gcis:Report .
}
SPARQL

my $results = $query->execute($model);
my @all;

while (my $row = $results->next) {
    push @all, $row;
};

ok @all==1, "got 1 result";
is $all[0]->{x}->value, "$server_base". "report/trees";

done_testing();

