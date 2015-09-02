package Tuba::DB::Object::PublicationContributorMap;

sub uri {
    my $s = shift;
    return ( "/publication/".$s->publication_id,
             "/contributor/".$s->contributor_id );
}

1;

