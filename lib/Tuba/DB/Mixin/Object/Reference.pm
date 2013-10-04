package Tuba::DB::Object::Reference;
# Tuba::DB::Mixin::Object::Reference;
use strict;
use Pg::hstore;

sub get_attr {
    my $s = shift;
    my $val = $s->attrs or return undef;
    return Pg::hstore::decode($val);
}

sub set_attr {
    my $s = shift;
    my ($k,$v) = @_;
    my $attr = $s->get_attr || {};
    $attr->{$k} = $v;
    $s->attrs(Pg::hstore::encode($attr));
}

1;

