#!perl

use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");

$t->app->db->dbh->do(q[delete from publication_type]);
for my $table (qw/figure finding chapter report dataset/) {
    $t->app->db->dbh->do(qq[insert into publication_type ("table",identifier) values ('$table','$table')]);
}

$t->ua->max_redirects(1);
$t->post_ok("/login" => form => {user => "unit_test", password => "anything"})->status_is(200);

# Make a report
$t->post_ok("/report" => json => {identifier => "pizzabrain"})->status_is(200);

# Make a chapter
$t->post_ok(
  "/report/pizzabrain/chapter" => json => {
    identifier        => "uno",
    report_identifier => "pizzabrain",
    title             => "Chapter one"
  }
)->status_is(200);

# Make a figure
$t->post_ok(
  "/report/pizzabrain/figure" => json => {
    identifier         => "pizza",
    chapter_identifier => "uno",
    report_identifier  => "pizzabrain"
  }
)->status_is(200);

# Make a dataset
$t->post_ok(
  "/dataset" => json => {
    identifier  => "dough",
  }
)->status_is(200);

# The figure wasBaked from that dataset
$t->post_ok(
  "/report/pizzabrain/figure/prov/pizza" => json => {
    parent_uri => "/dataset/dough",
    parent_rel => "prov:wasBaked",
    note       => "This pizza was baked from high quality gluten-free dough.",
  }
)->status_is(200);

# GET it, and check
$t->get_ok("/report/pizzabrain/chapter/uno/figure/pizza.json")->json_is(
  '/parents',
  [
    {
      url                         => "/dataset/dough",
      relationship                => "prov:wasBaked",
      publication_type_identifier => "dataset",
      label                       => 'dataset : dough',
      activity_uri                => undef,
      note => "This pizza was baked from high quality gluten-free dough."
    }
  ]
);

# Remove the association between this dataset and that figure.
$t->post_ok(
  "/report/pizzabrain/figure/prov/pizza"
  => { Accept => 'application/json' }
  => json => {
    delete => {
        parent_uri => "/dataset/dough",
        parent_rel => "prov:wasBaked",
    }
  }
)->status_is(200);

# Deleted?
$t->get_ok("/report/pizzabrain/chapter/uno/figure/pizza.json")->json_is(
  '/parents', [ ]
);

# Clean up
$t->delete_ok("/report/pizzabrain/chapter/uno/figure/pizza")->status_is(200);
$t->delete_ok("/dataset/dough")->status_is(200);
$t->delete_ok("/report/pizzabrain")->status_is(200);

done_testing();

1;

