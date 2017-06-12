use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;

my $t = Test::Mojo->new("Tuba");
$t->app->db->dbh->do(q[delete from publication_type where identifier='report']);
$t->app->db->dbh->do(q[insert into publication_type ("table",identifier) values ('report','report')]);
$t->app->db->dbh->do(q[delete from audit.logged_actions]);

$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);
$t->ua->max_redirects(0);

my $event_id = $t->ua->on(start => sub { pop->req->headers->header("Accept" => "application/json")});

# Make an org.
$t->post_ok("/organization" => json => { identifier => "earth", name => "Early Adopters of Real Technological Harmonicas" })
    ->status_is(302);
$t->get_ok("/organization/earth")
   ->status_is(200)
   ->json_is("/name" => "Early Adopters of Real Technological Harmonicas");

# Make an org, let it generate the identifier.
$t->post_ok("/organization" => json => {name => "Earth 2020" })
    ->status_is(302);
$t->get_ok("/organization/earth-2020")
   ->status_is(200)
   ->json_is("/name" => "Earth 2020");

# Make one more org.
$t->post_ok("/organization" => json => { identifier => "earth-2021", name => "Earthy 2021" })
    ->status_is(302);
$t->get_ok("/organization/earth-2021")
   ->status_is(200)
   ->json_is("/name" => "Earthy 2021");


# Add a person
$t->post_ok(
  "/person" => json => {
    url         => 'http://example.com/john_smith',
    last_name   => "Smith",
    middle_name => "T",
    first_name  => "John",
  }
)->status_is(302);
my $uri = $t->tx->res->headers->location;
like $uri, qr[/person/(\d+)$], "made a GCID";
my ($id) = $uri =~ qr[/person/(\d+)$];
$t->get_ok("/person/$id")
   ->status_is(200)
   ->json_is("/first_name" => "John")
   ->json_is("/last_name" => "Smith");

$t->ua->max_redirects(1);

# Make two publications and list two organizations with same person, same role different pubs.
$t->post_ok("/report" => json => { identifier => 'uno', title => 'Report Uno' })->status_is(200);
$t->post_ok("/report" => json => { identifier => 'dos', title => 'Report Dos' })->status_is(200);

$t->post_ok("/report/contributors/uno" => json =>
    {person_id => $id, organization_identifier => 'earth', role => 'engineer' })->status_is(200);
$t->post_ok("/report/contributors/dos" => json =>
    {person_id => $id, organization_identifier => 'earth-2020', role => 'engineer' })->status_is(200);

$t->get_ok("/report/uno")->json_is("/contributors/0/organization/identifier" => earth);
$t->get_ok("/report/dos")->json_is("/contributors/0/organization/identifier" => 'earth-2020');

$t->ua->max_redirects(0);

# What, these are the same organization?  Okay merge them.
# Delete organization2, merging into organization1
$t->ua->unsubscribe($event_id); # via form
$t->post_ok("/organization/earth-2020" => form => {
        delete => 1,
        replacement_identifier => "[organization] {earth} Early Adopters of Real Technological Harmonicas",
    })->status_is(302)
->header_is(Location => "/organization/form/update/earth");

# There is now one organization for both reports
$t->get_ok("/report/uno")->json_is("/contributors/0/organization/identifier" => earth);
$t->get_ok("/report/dos")->json_is("/contributors/0/organization/identifier" => earth);

# And redirect works.
$t->get_ok("/organization/earth-2020")->status_is(302)->header_is("Location" => "/organization/earth");

# Audit log for new person has both deleted people.
# For some reason, the deleted persons order id reversed in the log
$t->get_ok("/organization/history/earth")
    ->status_is(200)
    ->json_is("/change_log/0/action" => "I")
    ->json_is("/change_log/0/row_data/name" => "Early Adopters of Real Technological Harmonicas")
    ->json_is("/change_log/0/row_data/identifier" => earth)
    ->json_is("/change_log/1/action" => "D")
    ->json_is("/change_log/1/row_data/name" => "Earth 2020")
    ->json_is("/change_log/1/row_data/identifier" => 'earth-2020');

# Confirm the deprecated merge method is still functional
$t->post_ok("/organization/earth-2021/merge" => form => {
        merge_organization => "[organization] {earth} Early Adopters of Real Technological Harmonicas",
    })->status_is(302)
->header_is(Location => "/organization/form/update/earth");
$t->get_ok("/organization/earth-2021")->status_is(302)->header_is("Location" => "/organization/earth");


$t->delete_ok("/person/$id")->status_is(200);
$t->delete_ok("/report/uno")->status_is(200);
$t->delete_ok("/report/dos")->status_is(200);
$t->delete_ok("/organization/earth")->status_is(200);
$t->get_ok("/person/$id")->status_is(404);
$t->get_ok("/organization/earth")->status_is(404);

done_testing();
