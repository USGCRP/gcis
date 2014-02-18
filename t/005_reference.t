#!perl

use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;

use Tuba;
use Tuba::DB;
use v5.14;

my $t = Test::Mojo->new("Tuba");

$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);
$t->post_ok("/report" => form => { identifier => "test-report" } )->status_is(200);

my $desc = q[À l'exception de l'abondance de lichens, il y avait peu de différences dans la végétation entre les sites brûlés (moyenne = 37 ± 1,7 ans) et non brûlés.];
my $id = q[f13367d9-1e7f-40ca-a495-542d7a3faf98];

$t->app->db->dbh->do(q[delete from publication_type where identifier='report']);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('report','report')]);

$t->post_ok(
  "/reference" => json => {
    identifier      => $id,
    publication_uri => '/report/test-report',
    attrs           => { description => $desc },
    audit_note      => "this is an audit note",
  }
)->status_is(200);

my $base = $t->ua->app_url->clone;
$base->path('');
$base = "$base";
$base =~ s[/$][];

$t->get_ok("/reference/$id" => { Accept => "application/json" })->status_is(200)->json_is(
    {
        uri => "/reference/$id",
        href => "$base/reference/$id.json",
        publication_id => 1,
        publication_uri => "/report/test-report",
        child_publication_id => undef,
        sub_publication_uris => [],
        identifier => $id,
        attrs => { description => $desc },
    });

$t->get_ok("/reference/history/$id");
my $body  = $t->tx->res->body;
like $body, qr[this is an audit note], 'saved audit note in create';
#like $body, qr[À l'exception de l'abondance de lichens], 'unicode okay on history page';

$t->delete_ok("/reference/$id" => { Accept => "application/json" })->status_is(200);
$t->delete_ok("/report/test-report" => { Accept => "application/json" })->status_is(200);

done_testing();

1;

