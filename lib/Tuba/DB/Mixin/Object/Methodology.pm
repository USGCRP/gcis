package Tuba::DB::Object::Methodology;
# Tuba::DB::Mixin::Object::Methodology
use strict;

sub stringify {
    my $s = shift;
    return $s->publication->stringify;
}

sub uri {
    my $s = shift;
    return $s->publication->uri(@_);
}

1;

