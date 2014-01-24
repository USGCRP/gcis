package Tuba::DB::Object::Subpubref;
# Tuba::DB::Mixin::Object::Subpubref;

sub uri {
    return shift->publication->uri(@_);
}

1;

