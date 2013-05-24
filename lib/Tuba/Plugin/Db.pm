=head1 NAME

Tuba::Plugin::Db - Set up some helpers to be used in controllers.

=head1 SYNOPSIS

 app->plugin('db');

=head1 DESCRIPTION

This plugin sets up the following helpers :

 db : a DBIx::Connector object
 dbs : a DBIx::Simple object
 orm : a hashref mapping table names to class names.

=head1 SEE ALSO

L<Tuba::DB::Objects>, L<DBIx::Connector>, L<DBIx::Simple>

=cut

package Tuba::Plugin::Db;
use Mojo::Base qw/Mojolicious::Plugin/;
use DBIx::Connector;
use DBIx::Simple;
use SQL::Abstract;
use SQL::Interp;
use Module::Build::Database;
use Tuba::DB::Objects(); # do not call import since we call init explicitly

{
my $dbix;

sub register {
    my ($self, $app, $conf) = @_;

    my $dsn;
    if ($ENV{HARNESS_ACTIVE}) {
        my $mbd = Module::Build::Database->current;
        my $dbname = $mbd->database_options->{name} or die "no dbname in mbd object";
        my $host = $mbd->notes( 'dbtest_host' );
        $dsn = "dbi:Pg:dbname=gcis;host=$host";
    } else {
        my $dbname = $conf->{dbname} or die "no dbname in config file";
        $dsn = "dbi:Pg:dbname=$dbname";
        $dsn .= ":host=$conf->{host}" if $conf->{host};
        $dsn .= ":port=$conf->{port}" if $conf->{port};
        $app->log->info("Registering database $dbname");
    }

    $dbix = DBIx::Connector->new( $dsn, ($conf->{user} || ''),
       ( $conf->{password} || '' ),
       { RaiseError => 1, AutoCommit => 1 } );

    $app->helper( db => sub { $dbix } );
    $app->helper( dbs => sub { DBIx::Simple->new( shift->db->dbh ) } );

    Tuba::DB::Objects->init( $app );

    $app->helper( orm => sub { Tuba::DB::Objects->table2class });

    1;
}

sub connection {
    $dbix->dbh->{private_pid} = $$;
    $dbix->dbh->{pg_enable_utf8} = 1;
    $dbix;    
}
}


1;

