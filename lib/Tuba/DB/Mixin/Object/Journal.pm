package Tuba::DB::Object::Journal;
# Tuba::DB::Mixin::Object::Journal;

sub stringify {
    my $s = shift;
    return $s->title if $s->title;
    return $s->identifier;
}

1;

