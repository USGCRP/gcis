#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;

use_ok "Tuba";

my $t = Test::Mojo->new("Tuba");

$t->app->db->dbh->do(q[delete from publication_type]);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('article','article')]);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('journal','journal')]);

$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

my $base = $t->ua->server->url;

my %j = (
  identifier  => 'minecraft',
  title       => "Mine Craft",
  print_issn  => "0912-9138",
  online_issn => "2309-1231",
  publisher   => "miner man",
  country     => "US",
  url         => "http://minecraft.com",
  notes       => "Minekraft"
);

$t->post_ok("/journal.json" => json => \%j )->status_is(200);
$t->get_ok("/journal/minecraft.json")->json_is(
    {
        %j,
        uri => "/journal/minecraft",
        href => "${base}journal/minecraft.json",
        articles  => [],
        cited_by => [],
    }
);

$t->get_ok("/search.json?q=kraft&type=journal")
  ->status_is(200)
  ->json_is('/0/identifier' => 'minecraft');

$t->delete_ok('/journal/minecraft');

done_testing();

