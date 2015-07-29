#!perl

use Test::More;
use Test::Mojo;
use Swagger2;

my $t = Test::Mojo->new("Tuba");

$t->get_ok("/api_reference.yaml")->status_is(200);
my $yaml = $t->tx->res->body;

$t->get_ok("/api_reference.json")->status_is(200);
my $json = $t->tx->res->body;

my $swagger = Swagger2->new->parse($json);
my @errors = $swagger->validate;
ok !@errors, "valid swagger schema";
diag "Error: $_" for @errors;

done_testing();

