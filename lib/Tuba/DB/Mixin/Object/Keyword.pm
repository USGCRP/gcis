package Tuba::DB::Object::Keyword;
# Tuba::DB::Mixin::Object::Keyword;

sub stringify {
    my $self = shift;
    my %args = @_;
    my @all = grep defined && length, map $self->$_, qw/category topic term level1 level2 level3/;
    if ($args{short}) {
        return $all[-1];
    }
    return join ' > ', @all;
}

1;

