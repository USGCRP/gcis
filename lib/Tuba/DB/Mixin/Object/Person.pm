package Tuba::DB::Object::Person;

sub stringify {
    my $c = shift;
    return $c->name;
}

sub load_foreign {
    my $s = shift;
    #return unless $s->contributor_obj;
}

1;
