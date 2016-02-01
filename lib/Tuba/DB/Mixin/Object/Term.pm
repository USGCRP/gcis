package Tuba::DB::Object::Term;
use strict;

sub stringify {
    my $c = shift;
    return $c->label;
}

1;
