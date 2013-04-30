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
use Tuba::DB::Objects(); # do not call import since we call init explicitly

{
my $dbix;

sub register {
    my ($self, $app, $conf) = @_;
    my $dbname = $conf->{dbname} or die "no dbname in config file";

    $app->log->info("Registering database $dbname");

    my $dsn = "dbi:Pg:dbname=$dbname";
    $dsn .= ":host=$conf->{host}" if $conf->{host};
    $dsn .= ":port=$conf->{port}" if $conf->{port};

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
    $dbix;    
}
}


1;

