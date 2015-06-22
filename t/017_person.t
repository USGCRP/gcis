use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Test::Mojo;

my $t = Test::Mojo->new("Tuba");
$t->ua->max_redirects(1);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);
$t->ua->max_redirects(0);

$t->ua->on(start => sub { pop->req->headers->header("Accept" => "application/json")});

$t->post_ok("/person" => json =>
        { url => 'http://example.com/john_smith',
          last_name => "Smith",
          middle_name => "T",
          first_name => "John",
      })->status_is(302);
my $uri = $t->tx->res->headers->location;
like $uri, qr[/person/(\d+)$], "made a GCID";

my ($id) = $uri =~ qr[/person/(\d+)$];

$t->get_ok("/person/$id")
   ->status_is(200)
   ->json_is("/first_name" => "John");

$t->delete_ok("/person/$id")->status_is(200);

$t->get_ok("/person/$id")->status_is(404);

done_testing();
