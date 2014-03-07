package Tuba::DB::Object::Activity;
# Tuba::DB::Mixin::Object::Activity
use Data::UUID::LibUUID;
use strict;

__PACKAGE__->meta->primary_key_generator(sub {
    return new_uuid_string(4);
});

sub stringify {
    my $s = shift;
    return $s->identifier;
}

sub uri {
    my $s = shift;
    return "/activity/".$s->identifier;
}

1;

