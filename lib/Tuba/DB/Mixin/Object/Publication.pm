package Tuba::DB::Object::Publication;
# Tuba::DB::Mixin::Object::Publication;

use strict;

sub stringify {
    my $self = shift;
    return $self->publication_type.': '.$self->fk;
}


sub children {
    my $self = shift;

    return Tuba::DB::Object::Publication::Manager->get_objects(
        query => [ parent_id => $self->id ],
        limit => 100,
    );
}

1;

