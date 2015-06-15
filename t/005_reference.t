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
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);
$t->post_ok("/report" => form => { identifier => "test-report", title => "test report" } )->status_is(200);

my $desc = q[À l'exception de l'abondance de lichens, il y avait peu de différences dans la végétation entre les sites brûlés (moyenne = 37 ± 1,7 ans) et non brûlés.];
my $id = q[f13367d9-1e7f-40ca-a495-542d7a3faf98];

$t->app->db->dbh->do(q[delete from publication_type where identifier in ('report','book', 'article')]);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('report','report'),('book','book'), ('article','article')]);

$t->post_ok(
  "/reference" => json => {
    identifier      => $id,
    publication_uri => '/report/test-report',
    attrs           => { description => $desc },
    audit_note      => "this is an audit note",
  }
)->status_is(200);

my $base = $t->ua->server->url->clone;
$base->path('');
$base = "$base";
$base =~ s[/$][];

my $got = $t->app->db->dbh->selectall_arrayref(q[select id from publication where fk->'identifier' = 'test-report']);
my $pub_id = $got->[0][0];
like $pub_id, qr/\d+/, "got a publication id";

for my $uri ("/reference/$id", "/report/test-report/reference/$id") {
    $t->get_ok($uri => { Accept => "application/json" })->status_is(200)->json_is(
        {
            uri => "/reference/$id",
            href => "$base/reference/$id.json",
            child_publication => undef,
            publications => [
                "/report/test-report",
            ],
            identifier => $id,
            attrs => { description => $desc },
        });
}

$t->get_ok("/reference/$id.yaml")->content_like(qr[À l'exception de l'abondance de lichens]);

$t->get_ok("/reference/history/$id");
my $body  = $t->tx->res->body;
like $body, qr[this is an audit note], 'saved audit note in create';
#like $body, qr[À l'exception de l'abondance de lichens], 'unicode okay on history page';

# Update, associate the reference with an article.
my $article = "article-doi";
$t->post_ok("/journal" => json => { identifier => 'nature', print_issn => '1234-5678'} );
$t->post_ok("/article" => json => { identifier => $article, journal_identifier => 'nature' });

$t->post_ok("/reference/$id" => json => {
        identifier => $id,
        attrs => { description => $desc },
        child_publication => "/article/$article"
    })->status_is(200);

$t->get_ok("/reference/$id.json")->status_is(200)
  ->json_is("/child_publication" => "/article/$article");

# Make a book, convert to a report.
$t->post_ok("/book" => "form" => { identifier => 'test-book', title => 'some title' } );
$t->post_ok("/reference" => json => {
        identifier => "newrefid",
        publication_uri => "/report/test-report",
        attrs => { testattr => "testvalue" }
    })->status_is(200);
$t->post_ok("/reference/newrefid" => json => {
        identifier => "newrefid",
        child_publication => "/book/test-book",
        attrs => { testattr => "testvalue" }
    })->status_is(200);

# Convert
$t->post_ok(
  "/book/test-book" => "form" => {
     identifier => 'test-book', title => 'some title',
     convert_into_report => 1});
$t->get_ok( "/report/test-book" )->status_is(200);
$t->get_ok( "/reference/newrefid.json" )->status_is(200)->json_is(
    "/attrs" => { testattr => "testvalue" } );

$t->delete_ok("/reference/newrefid")->status_is(200);
$t->delete_ok("/report/test-book")->status_is(200);

$t->delete_ok("/reference/$id" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/report/test-report" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/article/$article");
$t->delete_ok("/journal/nature");

done_testing();

1;

