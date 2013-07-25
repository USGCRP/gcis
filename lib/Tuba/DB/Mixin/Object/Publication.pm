package Tuba::DB::Object::Publication;
# Tuba::DB::Mixin::Object::Publication;

use Pg::hstore qw/hstore_decode/;

use strict;

sub stringify {
    my $self = shift;
    return $self->publication_type.' : '.$self->to_object->stringify;
}

sub to_object {
    my $self = shift;
    my $orm = Tuba::DB::Objects->table2class;
    my $type = $self->publication_type_obj or die "no type for ".$self->id;
    my $obj_class = $orm->{$self->publication_type_obj->table}->{obj};
    my @pkcols = $obj_class->meta->primary_key_columns;
    my $pkvals = hstore_decode($self->fk);
    my $obj = $obj_class->new(%$pkvals);
    $obj->load(speculative => 1) or return;
    return $obj;
}

sub children {
    my $self = shift;

    return Tuba::DB::Object::Publication::Manager->get_objects(
        query => [ parent_id => $self->id ],
        limit => 100,
    );
}

sub get_parents {
    # Get objects which are parents of this one.
    # Returns an array of hashrefs : { relationship => 'foo', publication => $pub_object }
    my $self = shift;
    my $class = ref($self) || $self;
    my $dbh = $self->db->dbh;
    my $sth = $dbh->prepare(<<'SQL');
select p.*, m.relationship from publication p
    inner join publication_map m on m.parent=p.id
    where m.child = ?
SQL
    $sth->execute($self->id) or die $dbh->errstr;
    my $rows = $sth->fetchall_arrayref({});
    my @parents;
    for my $row (@$rows) {
        my %pub;
        @pub{qw/id publication_type fk/} = @$row{qw/id publication_type fk/};
        push @parents, { relationship => $row->{relationship}, publication => $class->new(%pub) };
    };
    return @parents;
}

1;

