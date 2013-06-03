package Tuba::DB::Object::Article;
# Tuba::DB::Mixin::Object::Article;

sub stringify {
    my $s = shift;
    return $s->title if $s->title;
    return $s->identifier;
}

1;

