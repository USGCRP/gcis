package Tuba::DB::Object::Finding;
# Tuba::DB::Mixin::Object::Finding;

sub stringify {
    my $c = shift;
    my %args = @_;
    return $c->statement if $args{long};
    return $c->identifier;
}

1;

