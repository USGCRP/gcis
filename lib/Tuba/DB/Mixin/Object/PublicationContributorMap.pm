package Tuba::DB::Object::PublicationContributorMap;

sub uri {
    my $s = shift;
    return ( $s->publication->uri(@_), $s->contributor->uri(@_) );
}

1;

