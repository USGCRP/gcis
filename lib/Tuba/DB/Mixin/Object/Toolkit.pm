package Tuba::DB::Object::Toolkit;
use strict;

sub stringify {
    my $self = shift;
    return $self->description;
}

1;
