package Tuba::DB::Object::Dataset;
# Tuba::DB::Mixin::Object::Dataset
use Tuba::Util qw[new_uuid];
use strict;

sub stringify {
    my $s = shift;
    return $s->name;
}

1;

