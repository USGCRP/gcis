package Tuba::DB::Object::Generic;
# Tuba::DB::Mixin::Object::Generic;
use strict;
use Pg::hstore;
use Encode;

__PACKAGE__->meta->column('attrs')->add_trigger(
    inflate => sub {
        my ($o,$v) = @_;
        my $h = Pg::hstore::decode($v);
        do { $_ = decode('UTF8',$_) } for values %$h;
        return $h;
    });

__PACKAGE__->meta->column('attrs')->add_trigger(
    deflate => sub {
        my ($o,$v) = @_;
        do { utf8::downgrade($_) if defined($_) } for values %$v;
        return Pg::hstore::encode($v);
    });

sub as_tree {
    my $s = shift;
    return $s->SUPER::as_tree(@_, deflate => 0);
}

1;

