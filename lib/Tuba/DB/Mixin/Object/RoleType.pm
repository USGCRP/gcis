package Tuba::DB::Object::RoleType;
use strict;

sub stringify {
    my $c = shift;
    return $c->label;
}

1;
