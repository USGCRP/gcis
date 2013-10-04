package Tuba::DB::Object::PublicationMap;
# Tuba::DB::Mixin::Object::PublicationMap;

sub child_publication {
    my $s = shift;
    return Tuba::DB::Object::Publication->new(id => $s->child)->load;
}

sub parent_publication {
    my $s = shift;
    return Tuba::DB::Object::Publication->new(id => $s->parent)->load;
}

1;

