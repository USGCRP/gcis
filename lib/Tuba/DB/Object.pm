package Tuba::DB::Object;
use DBIx::Simple;
use Tuba::Log;
use base 'Rose::DB::Object';

use strict;
use warnings;

# Override these in mixin classes, e.g. Tuba::DB::Mixin::Object::Chapter
sub stringify {
    my $s = shift;
    my $pk = $s->meta->primary_key;
    return $s->$pk;
}

sub uri {
    my $s = shift;
    my $c = shift;
    my $pk = $s->meta->primary_key;
    return $c->url_for( 'show_'.$s->meta->table, { $s->meta->table.'_'.$pk => $s->$pk } );
}

# https://groups.google.com/forum/?fromgroups#!searchin/rose-db-object/update$20primary$20key/rose-db-object/f8evi1dhp7c/IPhUUFS9aiEJ
sub update_primary_key {
    my $object = shift;
    my %changes = @_;
    my $audit_user = delete $changes{audit_user} or do {
        Carp::confess "missing audit user in update_primary_key";
    };
    my $audit_note = delete $changes{audit_note}; # Optional

    # Save current pk values in case there is a composite primary key and
    # we are only changing one piece.
    my %pk;
    for my $pk_col ($object->meta->primary_key_columns) {
        # use ->name, rather than accessor_method_name to be consistent with %changes.
        my $acc = $pk_col->name;
        $pk{$pk_col->name} = $object->$acc;
    }

    # %changes should just be source_column -> new_value.
    my $table = $object->meta->table;
    my %where;
    for my $col (keys %changes) {
        $where{$col} = $object->$col;
    }
    my $db = $object->db;
    $db->do_transaction( sub {
        $db->dbh->do("set local audit.username = ?",{},$audit_user);
        $db->dbh->do("set local audit.note = ?",{},$audit_note) if $audit_note;
        my $dbis = DBIx::Simple->new($db->dbh);
        $dbis->update($table, \%changes, \%where) or die $dbis->error;
    } ) or do {
        $object->error($db->error);
        return;
    };
    my $class = ref $object;
    my $replacement = $class->new( %pk, %changes )->load(speculative => 1);
    return $replacement;
}

sub save {
    my $self = shift;
    my %args = @_;
    my $status;
    my $audit_user = delete $args{audit_user} or do {
        Carp::confess "missing audit user in save";
    };
    my $audit_note = delete $args{audit_note}; # Optional
    $self->meta->error_mode('fatal');
    $status = $self->db->do_transaction( sub {
            $self->db->dbh->do("set local audit.username = ?",{},$audit_user);
            $self->db->dbh->do("set local audit.note = ?",{},$audit_note) if $audit_note;
            $self->SUPER::save(%args);
    } );
    unless ($status) {
        logger->warn("save failed, obj error : ".($self->error || 'none'));
        logger->warn("save failed, db error : ".($self->db->error || 'none'));
    }
    return $status;
}

1;

