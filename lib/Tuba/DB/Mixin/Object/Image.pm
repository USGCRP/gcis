package Tuba::DB::Object::Image;
# Tuba::DB::Mixin::Object::Image;

sub stringify {
    my $s = shift;
    my %args = @_;
    my $uuid = $s->identifier;
    # sample uuid : fb90f749-b7ba-47e3-a9db-111ec0d8363a
    if ($args{short}) {
        if ($uuid =~ /^(\w+)-(\w+)-(\w+)-(\w+)-(\w+)$/) {
            return $1;
        }
    }
    return $uuid;
}

1;

