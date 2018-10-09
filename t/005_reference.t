#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use open ':std', ':encoding(utf8)';
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;

use Tuba;
use Tuba::DB;
use v5.14;

my $t = Test::Mojo->new("Tuba");

$t->ua->max_redirects(1);

my $base = $t->ua->server->url->clone->path("") =~ s[/$][]r;

$t->app->db->dbh->do(q[delete from publication_type where identifier in ('report','book', 'article')]);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('report','report'),('book','book'), ('article','article')]);

$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);
$t->post_ok("/report" => form => { identifier => "test-report", title => "test report" } )->status_is(200);
$t->post_ok("/report" => form => { identifier => "test-nother-report", title => "test report" } )->status_is(200);

my $desc = q[À l'exception de l'abondance de lichens, il y avait peu de différences dans la végétation entre les sites brûlés (moyenne = 37 ± 1,7 ans) et non brûlés.];
my $reference_identifier = q[f13367d9-1e7f-40ca-a495-542d7a3faf98];

# Two reports with the same citation.
# NB: reference attrs will only be stored once.

# Create the reference for the first report.
$t->post_ok(
  "/reference" => { Accept => "application/json" } => json => {
    identifier  => $reference_identifier,
    publication => "/report/test-report",
    attrs       => { description => "$desc" },
    audit_note  => "this is an audit note for test-report",
})->status_is(200);
diag $t->tx->res->body unless $t->tx->res->code==200;

# Update the reference to add the second report.
$t->post_ok(
  "/reference/$reference_identifier" => { Accept => "application/json" } => json => {
    identifier  => $reference_identifier,
    publication => "/report/test-nother-report",
    attrs       => { description => "$desc" },
    audit_note  => "this is an audit note for test-nother-report",
})->status_is(200);

for my $uri ("/reference/$reference_identifier",
             "/report/test-report/reference/$reference_identifier",
             "/report/test-nother-report/reference/$reference_identifier"
   ) {
    $t->get_ok($uri => { Accept => "application/json" })->status_is(200)->json_is(
        {
            uri => "/reference/$reference_identifier",
            href => "$base/reference/$reference_identifier.json",
            child_publication => undef,
            publications => [
                "/report/test-report",
                "/report/test-nother-report",
            ],
            identifier => $reference_identifier,
            attrs => { description => "$desc" },
        });
}

$t->get_ok("/reference/$reference_identifier.yaml")->content_like(qr[À l'exception de l'abondance de lichens]);

$t->get_ok("/reference/history/$reference_identifier")
    ->content_like(qr[this is an audit note]);

# Update. Associate the reference with an article.
my $article_doi = "10.123/456.789";
$t->post_ok("/journal" => { Accept => "application/json" } => json => { identifier => 'nature', print_issn => '1234-5679'} );
$t->post_ok("/article" => { Accept => "application/json" } => json => { identifier => $article_doi, journal_identifier => 'nature' });

$t->post_ok("/reference/$reference_identifier" => { Accept => "application/json" } => json => {
        identifier => $reference_identifier,
        attrs => { description => $desc },
        child_publication => "/article/$article_doi"
    })->status_is(200);

$t->get_ok("/reference/$reference_identifier.json")->status_is(200)
  ->json_is("/child_publication" => "/article/$article_doi");

# Make a book, convert to a report, ensure reference is still connected.
$t->post_ok("/book" => "form" => { identifier => 'test-book', title => 'some title' } );
$t->post_ok("/reference" => { Accept => "application/json" } => json => {
        identifier => "newrefid",
        publication => "/report/test-report",
        attrs => { testattr => "testvalue" }
    })->status_is(200);
$t->post_ok("/reference/newrefid" => { Accept => "application/json" } => json => {
        identifier => "newrefid",
        child_publication => "/book/test-book",
        attrs => { testattr => "testvalue" }
    })->status_is(200);
$t->post_ok(
  "/book/test-book" => "form" => {
     identifier => 'test-book', title => 'some title',
     convert_into_report => 1});
$t->get_ok( "/report/test-book" )->status_is(200);
$t->get_ok( "/reference/newrefid.json" )->status_is(200)->json_is(
    "/attrs" => { testattr => "testvalue" } );

# Add a reference attribute
$t->post_ok("/reference/$reference_identifier" => form => {
        new_attr_key   => 'test_attribute_key',
        new_attr_value => 'test_attribute_value'
    })->status_is(200);
$t->get_ok( "/reference/$reference_identifier" => { Accept => "application/json" })->status_is(200)->json_has( '/attrs', { test_attribute_key => "test_attribute_value" });

# Update the reference attributes
$t->post_ok("/reference/$reference_identifier" => form => {
        attribute_test_attribute_key => 'replacement_test_attr_value',
    })->status_is(200);
$t->get_ok( "/reference/$reference_identifier" => { Accept => "application/json" })->status_is(200)->json_has( '/attrs', { test_attribute_key => "replacement_test_attr_value" });

# Delete a reference attribute
$t->post_ok("/reference/$reference_identifier" => form => {
        delete_pub_attr => "test_attribute_key",
    })->status_is(200);
$t->get_ok( "/reference/$reference_identifier" => { Accept => "application/json" })->status_is(200)->json_is( '/attrs', { description => "$desc" } );


# Cleanup
$t->delete_ok("/reference/newrefid")->status_is(200);
$t->delete_ok("/report/test-book")->status_is(200);
$t->delete_ok("/reference/$reference_identifier" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/report/test-report" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/report/test-nother-report" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/article/$article_doi");
$t->delete_ok("/journal/nature");

done_testing();

1;

