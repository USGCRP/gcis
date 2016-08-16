package Tuba::DB::Object::Dataset;
use strict;

sub stringify {
    my $c = shift;
    return $c->name || $c->SUPER::stringify(@_);
}

1;

