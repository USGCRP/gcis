#!perl

# Ontology sanity checks.
use open ':std', ':encoding(utf8)';
use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::Mojo;
use tlib;
use strict;

my $t = Test::Mojo->new("Tuba");

$t->get_ok("/gcis.owl")
    ->status_is(200)
    ->content_type_is('text/html')
    ->content_like(qr[DOCTYPE html])
    ->content_like(qr[\Q<h1>GCIS Ontology</h1>\E]);

$t->get_ok("/gcis.owl" => { Accept => "text/turtle" } )
    ->status_is(200)
    ->content_type_is('text/turtle')
    ->turtle_ok
    ->content_like(qr[\Qprefix gcis: <http://data.globalchange.gov/gcis.owl#> .\E]);

$t->get_ok("/gcis.owl" => { Accept => "application/x-turtle" } )
    ->status_is(200)
    ->content_type_is('text/turtle')
    ->turtle_ok
    ->content_like(qr[\Qprefix gcis: <http://data.globalchange.gov/gcis.owl#> .\E]);

$t->get_ok("/gcis.owl" => { Accept => "application/n-triples" } )
  ->content_like(qr[\Q<http://data.globalchange.gov/gcis.owl> <http://www.w3.org/2000/01/rdf-schema#label> "GCIS Ontology" .\E])
  ->status_is(200);

$t->get_ok("/gcis.owl" => { Accept => "application/rdf+xml" } )
  ->status_is(200)
  ->content_like(qr{\Q<rdf:Description rdf:about="http://data.globalchange.gov/gcis.owl">\E});

done_testing();

1;

