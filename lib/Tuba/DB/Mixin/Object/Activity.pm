package Tuba::DB::Object::Activity;
# Tuba::DB::Mixin::Object::Activity
use Tuba::Util qw[new_uuid];
use strict;

__PACKAGE__->meta->primary_key_generator(sub {
    return new_uuid();
});

sub stringify {
    my $s = shift;
    return $s->identifier;
}

1;

