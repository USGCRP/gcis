package Tuba::DB::Object::CaseStudy;
use strict;

sub stringify {
    my $self = shift;
    return $self->description;
}

1;
