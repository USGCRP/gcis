package Tuba::DB::Object::File;
use Mojo::ByteStream qw/b/;
use strict;
# Tuba::DB::Mixin::Object::File;

sub thumbnail {
    my $s = shift;
    my $c = shift || Carp::confess 'missing controller';
    my %args = (width => 100, height => 100, @_);
    if ($s->file =~ /\.txt$/) {
        %args = (width => '90%', height => '400');
        return $c->tag('iframe', src => '/img/'.$s->file => %args, sub {} );
    }
    return $c->image( '/img/'.$s->file, %args);
}

1;

