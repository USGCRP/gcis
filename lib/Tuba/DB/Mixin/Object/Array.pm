package Tuba::DB::Object::Array;
# Tuba::DB::Mixin::Object::Array;
use Mojo::ByteStream qw/b/;
use Tuba::Util qw[new_uuid];
use List::Util qw/max/;
use strict;

__PACKAGE__->meta->primary_key_generator(sub {
    return new_uuid();
});

sub stringify {
    my $s = shift;
    my %args = @_;
    my $uuid = $s->identifier;
    # sample uuid : fb90f749-b7ba-47e3-a9db-111ec0d8363a
    if ($args{short}) {
        if ($uuid =~ /^(\w+)-(\w+)-(\w+)-(\w+)-(\w+)$/) {
            return $1.' ('.$s->dimensions.')';
        }
    }
    return $uuid;
}

sub dimensions {
    my $s = shift;
    return 'empty' unless $s->rows;
    return sprintf ('%dx%d',$s->row_count, $s->col_count);
}

sub row_count {
    my $s = shift;
    my $rows = $s->rows or return 0;
    return 0 unless ref $rows eq 'ARRAY';
    return scalar @$rows;
}

sub col_count {
    my $s = shift;
    my $rows = $s->rows or return 0;
    return 0 unless ref $rows eq 'ARRAY';
    my $max = max map { scalar @$_ } @$rows;
    return $max;
}

1;

