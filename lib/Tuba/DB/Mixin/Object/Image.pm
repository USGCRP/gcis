package Tuba::DB::Object::Image;
# Tuba::DB::Mixin::Object::Image;

sub stringify {
    my $s = shift;
    my $uuid = $s->identifier;
    # sample uuid : fb90f749-b7ba-47e3-a9db-111ec0d8363a
    return $uuid unless $uuid =~ /^(\w+)-(\w+)-(\w+)-(\w+)-(\w+)$/;
    return $1;
}

1;

