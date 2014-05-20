#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More;
use Test::MBD qw/-autostart/;
use Tuba::DB::Objects qw/-autoconnect -nicknames/;
use Test::Mojo;
use v5.14;

my $t = Test::Mojo->new("Tuba");
ok $t, "Made a Test::Mojo object";

my $dbh = $t->app->db->dbh;
ok $dbh, "got a dbh";

$dbh->do(q[delete from publication_type where identifier='report']);
$dbh->do(q[insert into publication_type ("table",identifier) values ('report','report')]);

my $report = Report->new(identifier => "soccer", title => "scouting report");
ok $report->save(audit_user => "test"), "Saved report";
my $pub = $report->get_publication(autocreate => 1);
$pub->save(audit_user => "test"), "Saved publication";

my $ref = Reference->new(
    identifier => "ronaldo",
    publication_id => $pub->id,
    attrs => { num => "7 ± 1" }
);
ok $ref->save(audit_user => "test"), "Saved reference";

my $found = Reference->new(identifier => "ronaldo");
ok $found->load(speculative => 1), "loaded reference";
is $found->attrs->{num}, "7 ± 1", "got unicode value back";

my $rows = $dbh->selectall_arrayref("select * from reference where identifier='ronaldo'",{Slice =>{}});
is $rows->[0]{attrs}, q["num"=>"7 ± 1"], "db handle returned unicode";
ok $report->delete, 'delete report';
ok $ref->delete, 'delete ref';

done_testing();


