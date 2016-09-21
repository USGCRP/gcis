package Tuba::DB::Object::Dataset;
# Tuba::DB::Mixin::Object::Dataset
use strict;

sub stringify {
    my $s = shift;
    return $s->name || $s->SUPER::stringify(@_);
}

1;

