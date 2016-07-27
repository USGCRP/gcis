=head1 NAME

Tuba::DB::Objects -- Make Rose::DB::Object-derived classes for tuba.

=head1 SYNOPSIS

 use Tuba::DB::Objects;
 Tuba::DB::Object::Image->delete_objects(all => 1);
 my $file = Tuba::DB::Object::File->new(file => 'foo');
 $file->save or die $file->error;

 # Optionally create nicknames which are easier to type :
 use Tuba::DB::Objects qw/-nicknames/;
 Images->delete_objects(all => 1);
 my $file = File->new(file => 'foo');
 $file->save or die $file->error;

=head1 DESCRIPTION

Use this class to load classes into the Tuba::DB::Object namespace.

The database schema is introspected and accessors, etc. are all created
based on the schema.

=head1 SEE ALSO

L<Rose::DB::Object::Loader>

=cut

package Tuba::DB::Objects;
use Rose::DB::Object::Loader;
use Tuba;
use Tuba::DB;
use Tuba::DB::Object::Manager;
use Tuba::DB::Object::ConventionManager;
use YAML::Syck;
use Tuba::Log;

use strict;
use warnings;

our %table2class;

sub import {
    my $class = shift;
    my $caller = caller;

    if ($ENV{TUBA_CLI} or (grep /-autoconnect/, @_)) {
        # Load configuration from app.
        my $app = Tuba->new();
        my $db = $app->db or die "no database object";
        $class->init( db => $app->db );
    } else {
        $class->init();
    }

    no strict 'refs';
    if (grep /-nicknames/, @_) {
        for my $table (keys %table2class) {
            {
                my $manager_class = $table2class{$table}{mng};
                my $alias = $manager_class;
                $alias =~ s/Tuba::DB::Object:://;
                $alias =~ s/::Manager$/s/;
                *{$caller.'::'.$alias} = sub { $manager_class };
            }

            {
                my $object_class = $table2class{$table}{obj};
                my $alias = $object_class;
                $alias =~ s/Tuba::DB::Object:://;
                *{$caller.'::'.$alias} = sub { $object_class };
            }
        }
    }
}

sub init {
    my $class = shift;
    my %args = @_;
    return if keys %table2class;

    my $db_schema = Tuba::Plugin::Db->schema;

    my $cm = Tuba::DB::Object::ConventionManager->new();
    my $loader = Rose::DB::Object::Loader->new(
        class_prefix => 'Tuba::DB::Object',
        db_schema => $db_schema,
        base_classes => [qw/Tuba::DB::Object Rose::DB::Object::Helpers/ ],
        manager_base_classes => [qw/Tuba::DB::Object::Manager/],
        convention_manager => $cm,
        include_views => 1,            #Added for db view 'vocabulary'
        require_primary_key => 0,      #Added because views cannot have primary keys in postgres
                                       # so see Tuba/DB/Mixin/Object/Vocabulary.pm for workaround
    );

    my @made = $loader->make_classes(
        $args{db} ? ( db => $args{db} ) :
                    ( db_class => 'Tuba::DB' )
    );
    for my $made (@made) {
    #logger->debug("Made $made");  #uncomment to see all classes that are made from db
        my $mixin = $made;
        $mixin =~ s/Tuba::DB/Tuba::DB::Mixin/;
        eval " require $mixin";
        my $path = $mixin;
        $path =~ s[::][/]g;
        if ($@ and $@ !~ m[Can't locate $path.pm]) {
            warn "#$@";
            die $@;
        }
        $made->add_extra if $made->can('add_extra');
    }
    die "Could not make classes" unless @made;
    for (@made) {
        if ($_->isa("Rose::DB::Object::Manager")) {
            $table2class{$_->object_class->meta->table}{mng} = $_;
        } else {
            $table2class{$_->meta->table}{obj} = $_;
        }
    }
}

sub table2class {
    return \%table2class;
}

1;

