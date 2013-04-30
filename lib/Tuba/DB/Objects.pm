=head1 NAME

Tuba::DB::Objects -- objects which correspond exactly to the database schema.

=head1 SYNOPSIS

 use Tuba::DB::Objects;

 my $file = Tuba::DB::Object::File->new(file => 'foo');
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

use strict;
use warnings;

our %table2class;

sub import {
    shift->init();
}

sub init {
    my $class = shift;
    my $app = shift || Tuba->new();
    return if keys %table2class;

    my $conf = $app->config;

    my $db_schema = $conf->{database}{schema};

    my $loader = Rose::DB::Object::Loader->new( class_prefix => 'Tuba::DB::Object', db_schema => $db_schema );

    my @made = $loader->make_classes(db_class => 'Tuba::DB' );
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

