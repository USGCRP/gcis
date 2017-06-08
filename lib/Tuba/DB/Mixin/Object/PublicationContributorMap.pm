package Tuba::DB::Object::PublicationContributorMap;
use Tuba::Log;

sub uri {
    my $s = shift;
    return ( "/publication/".$s->publication_id,
             "/contributor/".$s->contributor_id );
}


sub merge_into {
    my $s = shift;
    my %args = @_;
    my $new = $args{new};
    my $audit_user = $args{audit_user};
    my $audit_note = $args{audit_note};

    my $target_map = Tuba::DB::Object::PublicationContributorMap->new(
        publication_id => $s->publication_id, 
        contributor_id => $new->id
    );
    if ( $target_map->load(speculative => 1) ) {
        # Case 1a: there is already a publication_contributor_map
        # for this publication on both contributors.
        # Compare reference linked on map
        if ( $s->reference_id ) {
            if ( $target_map->reference_id ) {
                # merge process cannot handle conflicting reference_ids!
                die "Cannot merge Publication Contributor Maps with differing references"
                    if $s->reference_id ne $target_map->reference_id;
            }
            else {
                # move over the reference_id
                $target_map->reference_id( $s->reference_id );
            }
        }
        $target_map->save(audit_user => $audit_user, audit_note => $audit_note)
            or die $target_map->error;
    }
    else {
        # Case 1b: there is not a publication_contributor_map for
        # this publication on the target contributor. Save to target.
        $target_map->save(audit_user => $audit_user, audit_note => $audit_note)
            or die $target_map->error;
    }
    return 1;
}

1;

