package Tuba::DB::Object;
use DBIx::Simple;

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
    my $db = DBIx::Simple->new($object->db->dbh);
    $db->dbh->{RaiseError} = 0;
    my $result = $db->update($table, \%changes, \%where) or do {
        $object->error($db->error);
        return undef;
    };
    my $class = ref $object;
    my $replacement = $class->new( %pk, %changes )->load(speculative => 1);
    return $replacement;
}

1;

