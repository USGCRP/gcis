package Tuba::DB::Object::Relationship;
use strict;

sub stringify {
    my $c = shift;
    return $c->identifier;
}

1;
