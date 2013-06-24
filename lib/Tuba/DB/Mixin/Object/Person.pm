package Tuba::DB::Object::Person;

sub prov_type {
    my $self = shift;
    return sprintf(q[http://www.w3.org/ns/prov#%s], ucfirst($self->meta->table) );
}

sub foaf_type {
    my $self = shift;
    return sprintf(q[http://xmlns.com/foaf/0.1/%s], ucfirst($self->meta->table) );
}
sub stringify {
    my $c = shift;
    return $c->name;
}

sub load_foreign {
    my $s = shift;
    #return unless $s->contributor_obj;
}

1;
