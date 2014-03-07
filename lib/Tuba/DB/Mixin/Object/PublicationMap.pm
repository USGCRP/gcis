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

sub as_tree {
    my $s = shift;
    my $tree = $s->SUPER::as_tree(@_);
    $tree->{parent_uri} = "/publication/".$tree->{parent};
    $tree->{child_uri} = "/publication/".$tree->{child};
    return $tree;
}

1;

