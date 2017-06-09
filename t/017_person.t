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

# Add another one just like that one.
$t->post_ok(
  "/person" => json => {
    url         => 'http://example.com/john_smyth',
    last_name   => "Smyth",
    middle_name => "T",
    first_name  => "John",
  }
)->status_is(302);
my $uri = $t->tx->res->headers->location;
like $uri, qr[/person/(\d+)$], "made a GCID";
my ($id2) = $uri =~ qr[/person/(\d+)$];
$t->get_ok("/person/$id2")
   ->status_is(200)
   ->json_is("/first_name" => "John")
   ->json_is("/last_name" => "Smyth");

# Add another one just like that one.
$t->post_ok(
  "/person" => json => {
    url         => 'http://example.com/j_smyth',
    last_name   => "Smyth",
    middle_name => "T",
    first_name  => "J",
  }
)->status_is(302);
my $uri = $t->tx->res->headers->location;
like $uri, qr[/person/(\d+)$], "made a GCID";
my ($id3) = $uri =~ qr[/person/(\d+)$];
$t->get_ok("/person/$id3")
   ->status_is(200)
   ->json_is("/first_name" => "J")
   ->json_is("/last_name" => "Smyth");

$t->ua->max_redirects(1);

# Also make an org.
$t->post_ok("/organization" => json => { identifier => "earth", name => "Early Adopters of Real Technological Harmonicas" })
    ->status_is(200);

# Make two publications and list two people with same org, same role
# different pubs.
$t->post_ok("/report" => json => { identifier => 'uno', title => 'Report Uno' })->status_is(200);
$t->post_ok("/report" => json => { identifier => 'dos', title => 'Report Dos' })->status_is(200);

$t->post_ok("/report/contributors/uno" => json =>
    {person_id => $id, organization_identifier => 'earth', role => 'engineer' })->status_is(200);
$t->post_ok("/report/contributors/dos" => json =>
    {person_id => $id2, organization_identifier => 'earth', role => 'engineer' })->status_is(200);
$t->post_ok("/report/contributors/dos" => json =>
    {person_id => $id3, organization_identifier => 'earth', role => 'engineer' })->status_is(200);

$t->get_ok("/report/uno")->json_is("/contributors/0/person/id" => $id);
$t->get_ok("/report/dos")->json_is("/contributors/0/person/id" => $id2);
$t->get_ok("/report/dos")->json_is("/contributors/1/person/id" => $id3);

# test lookups
$t->post_ok(
  "/person" => json => {
    url         => 'http://example2.com/john_smith',
    last_name   => "smithers",
    middle_name => undef,
    first_name  => "john t.",
  });

$t->post_ok(
  "/person/lookup/name" => json => {
      last_name => "SMIthERS",
      first_name => "John t",
  } => { Accept => 'application/json' }
)->status_is(200)
->json_is('/first_name' => 'john t.')
->json_is('/last_name' => 'smithers');

my $person_uri = $t->tx->res->json->{uri};
$t->delete_ok($person_uri)->status_is(200);

$t->ua->max_redirects(0);

# What, these are all the same person?  Okay merge them.
# Delete person2, merging into person1
$t->ua->unsubscribe($event_id); # via form
$t->post_ok("/person/$id2" => form => {
        delete => 1,
        replacement_identifier => "[person] {$id} John Smith",
    })->status_is(302)
->header_is(Location => "/person/form/update/$id");

# Delete person3, merging into person1
$t->delete_ok("/person/$id3" => json => { # via JSON
        replacement => "/person/$id"
    })->status_is(200);


# There is now one person for both reports
$t->get_ok("/report/uno")->json_is("/contributors/0/person/id" => $id);
$t->get_ok("/report/dos")->json_is("/contributors/0/person/id" => $id);

# Also both reports are listed for that person.
$t->get_ok("/person/$id")->status_is(200)
  ->json_is("/contributors/0/publications" =>
    [ { uri => "/report/uno" }, { uri => "/report/dos" } ]);

# And redirect works.
$t->get_ok("/person/$id2")->status_is(302)->header_is("Location" => "/person/$id");
$t->get_ok("/person/$id3")->status_is(302)->header_is("Location" => "/person/$id");

# Audit log for new person has both deleted people.
# For some reason, the deleted persons order id reversed in the log
$t->get_ok("/person/history/$id")
    ->status_is(200)
    ->json_is("/change_log/0/action" => "I")
    ->json_is("/change_log/0/row_data/last_name" => "Smith")
    ->json_is("/change_log/0/row_data/id" => $id)
    ->json_is("/change_log/1/action" => "D")
    ->json_is("/change_log/1/row_data/first_name" => "J")
    ->json_is("/change_log/1/row_data/id" => $id3)
    ->json_is("/change_log/2/action" => "D")
    ->json_is("/change_log/2/row_data/last_name" => "Smyth")
    ->json_is("/change_log/2/row_data/id" => $id2);

$t->delete_ok("/person/$id")->status_is(200);
$t->delete_ok("/report/uno")->status_is(200);
$t->delete_ok("/report/dos")->status_is(200);
$t->get_ok("/person/$id")->status_is(404);
$t->delete_ok("/organization/earth")->status_is(200);

done_testing();
