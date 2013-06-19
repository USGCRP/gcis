package Tuba::DB::Object::Organization;

sub stringify {
    my $self = shift;
    $self->fk;
}

# TODO override load instead
sub load_foreign {
    my $self = shift;
    my $table = $self->organization_type_obj->table;
    my $class = Tuba::DB::Objects->table2class->{$table}{obj};
    my $extra = $class->new(identifier => $self->fk)->load(speculative => 1);
    $self->{org} = $extra;
    return $self;
}
