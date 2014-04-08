#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::More tests => 2;
use Test::MBD qw/-autostart/;
use DBI;

my $mbd = Module::Build::Database->current;
my $host = $mbd->notes( 'dbtest_host' );

my $dbh = DBI->connect("dbi:Pg:dbname=gcis;host=$host");
ok $dbh, "connected to $host";
my $rows = $dbh->selectall_arrayref('select 42');
is $rows->[0][0], 42, 'ran select statement';

1;

