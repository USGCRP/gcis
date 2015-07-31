package Tuba::DB::Object::Person;
use strict;

sub stringify {
    my $c = shift;
    my %a = @_;
    if ($a{long} && $c->orcid) {
        return sprintf ('%s (%s)',$c->name,$c->orcid // 'no orcid');
    }
    return $c->name;
}

sub name {
    my $s = shift;
    return sprintf('%s %s', $s->first_name // '', $s->last_name // '');
}

sub uri {
    my $s          = shift;
    my $c          = shift;
    my $opts       = shift;
    my $route_name = $opts->{tab} || 'show';
    $route_name .= '_person';

    return $c->url_for($route_name) unless ref($s);
    return $c->url_for($route_name, { person_identifier => $s->id } );
}

sub merge_into {
    my $s = shift;
    my %args = @_;
    my $new = $args{new};
    my $audit_user = $args{audit_user};
    my $audit_note = $args{audit_note};

    die "Not replacing person with orcid : ".$new->id." vs ".$s->id if $s->orcid;

    # ids for other contributors
    for my $contributor (@{ Tuba::DB::Object::Contributor::Manager->get_objects(
            query => [ person_id => $s->id ]) }) {
        my $record = Tuba::DB::Object::Contributor->new(
          role_type_identifier    => $contributor->role_type_identifier,
          organization_identifier => $contributor->organization_identifier,
          person_id               => $new->id
        );
        if ($record->load(speculative => 1)) {
            # Case 1:
            # Already a contributor record for this role + org?
            # Assign all publication maps for '$contributor' to '$record' and remove '$contributor'
            #
            # before:
            #     person 1 -- contributor 1 -- map entry -- publication 1
            #     person 2 -- contributor 2 -- map entry -- publication 2
            # after:
            #     person 1 --\                    /--- map entry -- publication 1  
            #                 --- contributor 3 --
            #     person 2 --/                    \--- map entry -- publication 2
            #
            for my $pm (@{ Tuba::DB::Object::PublicationContributorMap::Manager->get_objects(query => [ contributor_id => $contributor->id ]) }) {
                    my $map = Tuba::DB::Object::PublicationContributorMap->new(publication_id => $pm->publication_id, contributor_id => $record->id);
                    $map->load(speculative => 1) and next;
                    $map->save(audit_user => $audit_user, audit_note => $audit_note) or die $map->error;
            }
            $contributor->delete(audit_user => $audit_user, audit_note => $audit_note) or die $contributor->error;
        } else {
            # Case 2:
            # Easier, just use existing contributor record but our person id.
            # before:
            #      person 1 -- contributor 1 --- map entries -- publications
            # after:
            #      person 2 -- contributor 1 --- map entries -- publications
            #
            $contributor->person_id($new->id);
            $contributor->save(audit_user => $audit_user, audit_note => $audit_note) or die $contributor->error;
        }
    }
    return 1;
}

1;
