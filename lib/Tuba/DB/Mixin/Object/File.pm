package Tuba::DB::Object::File;
use Mojo::ByteStream qw/b/;
use strict;
# Tuba::DB::Mixin::Object::File;

sub as_tree {
    my $s = shift;
    my %a = @_;
    my $tree = $s->SUPER::as_tree(@_);
    my $c = $a{c} or return $tree;
    $tree->{url} = '/img/'.$s->file;
    return $tree;
}


1;

