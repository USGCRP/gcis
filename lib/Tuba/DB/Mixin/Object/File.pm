package Tuba::DB::Object::File;
# Tuba::DB::Mixin::Object::File;
use Mojo::ByteStream qw/b/;
use Data::UUID::LibUUID;
use strict;

sub as_tree {
    my $s = shift;
    my %a = @_;
    my $tree = $s->SUPER::as_tree(@_);
    my $c = $a{c} or return $tree;
    $tree->{url} = '/img/'.$s->file;
    $tree->{href} = $c->url_for($tree->{url})->to_abs;
    return $tree;
}

__PACKAGE__->meta->primary_key_generator(sub {
    return new_uuid_string(4);
});


1;

