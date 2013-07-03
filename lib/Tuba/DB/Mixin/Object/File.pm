package Tuba::DB::Object::File;
use Mojo::ByteStream qw/b/;
use strict;
# Tuba::DB::Mixin::Object::File;

sub thumbnail {
    my $s = shift;
    my $c = shift || Carp::confess 'foo';
    return $c->image( '/img/'.$s->file, width =>"100px", height => "100px" );
}

1;

