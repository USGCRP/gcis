package Tuba::DB::Object::Country;
use strict;

sub uri {
    return;
}

sub stringify {
    my $c = shift;
    return $c->name;
}

1;

