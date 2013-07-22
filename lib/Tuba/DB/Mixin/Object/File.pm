package Tuba::DB::Object::File;
use Mojo::ByteStream qw/b/;
use strict;
# Tuba::DB::Mixin::Object::File;

sub thumbnail {
    my $s = shift;
    my $c = shift || Carp::confess 'missing controller';
    my %args = (width => 100, height => 100, @_);
    return $c->image( '/img/'.$s->file, %args);
}

1;

