package Tuba::Plugin::Db;
use Mojo::Base qw/Mojolicious::Plugin/;
use DBIx::Connector;
use DBIx::Simple;
use SQL::Abstract;
use SQL::Interp;
use Rose::DB::Object::Loader;
use Tuba::DB;

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

    my $rose_db = Tuba::DB->new();
    my $loader = Rose::DB::Object::Loader->new( class_prefix => 'Tuba::Obj', db_schema => $conf->{schema} );
    my @made = $loader->make_classes(db_class => 'Tuba::DB' );
    $app->log->info("Loaded ".@made." classes");

    my %orm; # Map table names to class names.
    for (@made) {
        if ($_->isa("Rose::DB::Object::Manager")) {
            $orm{$_->object_class->meta->table}{mng} = $_;
        } else {
            $orm{$_->meta->table}{obj} = $_;
        }
    }
    $app->helper(orm => sub { \%orm });

    1;
}

sub connection {
    $dbix;    
}
}


1;

