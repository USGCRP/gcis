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
  identifier  => 'nature',
  title       => "Nature",
  print_issn  => "1234-5679",
  online_issn => "1234-8678",
  publisher   => "nature publishing co",  #deprecated
  country     => "US",
  url         => "http://nature.com",
  notes       => "this is nature"
);

$t->post_ok("/journal" => json => \%j )->status_is(200);
$t->get_ok("/journal/nature.json")->json_is(
    {
        %j,
        uri => "/journal/nature",
        href => "${base}journal/nature.json",
        articles  => [],
        cited_by => [],
    }
);

my %k = %j;
$k{identifier} = 'nurture';
$k{print_issn} = '2323-1319';
$k{online_issn} = '3131-3124';
$k{url} = 'http://nurture.com';
$k{title} = 'Nurture';

$t->post_ok("/journal" => json => \%k )->status_is(200);
$t->get_ok("/journal/nurture.json")->json_is(
    {
        %k,
        uri => "/journal/nurture",
        href => "${base}journal/nurture.json",
        articles  => [],
        cited_by => [],
    }
);

my %a = (
 identifier         => '10.123/456',
 title              => 'nature vs nurture',
 doi                => '10.123/456',
 year               => '2001',
 journal_identifier => 'nature',
 journal_vol        => 12,
 journal_pages      => '12-33',
 url                => 'http://nature.com/nvn.pdf',
 notes              => 'an important article',
 );

$t->post_ok("/article" => json => \%a )->status_is(200);
$t->get_ok("/article/10.123/456.json")
  ->json_is({%a, uri => "/article/10.123/456", href => "${base}article/10.123/456.json", cited_by => []});

my %b = %a;
$b{doi} = '10.223/333';
$b{identifier} = $b{doi};
$b{url} = "http://nurture.com/nvn.pdf";
$t->post_ok("/article" => form => \%b )->status_is(200);
$t->get_ok("/article/10.223/333.json")
  ->json_is({%b, uri => "/article/10.223/333", href => "${base}article/10.223/333.json", cited_by => []});

$t->delete_ok("/article/10.223/333");
$t->delete_ok("/article/10.123/456");
$t->delete_ok('/journal/nature');
$t->delete_ok('/journal/nurture');

done_testing();

