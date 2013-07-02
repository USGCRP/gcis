package Tuba::DB::Object::Keyword;
# Tuba::DB::Mixin::Object::Keyword;

sub stringify {
    my $self = shift;
    return join ' > ', grep defined && length, map $self->$_, qw/category topic term level1 level2 level3/;
}

1;

