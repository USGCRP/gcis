package Tuba::DB::Object::Contributor;
use strict;
use Tuba::Log;

sub stringify {
    my $c = shift;
    my ($person, $org);
    eval {
        $person = $c->person;
        $org = $c->organization;
    };
    my $role =  $c->role_type->label;
    if ($person && $org) {
        return sprintf('%s : %s (%s) ',$role, $person->stringify, $org->stringify );
    }
    if ($person) {
        return sprintf('%s : %s ',$role, $person->stringify );
    }
    if ($org) {
        return sprintf('%s : %s ',$role, $org->stringify );
    }
    return sprintf('Unknown %s : %s ',$role, $c->id );
}

sub as_text {
    my $c = shift;
    if (my $person = $c->person) {
        if (my $org = $c->organization) {
            return sprintf('%s (%s)', $person->stringify, $org->stringify);
        }
        return $person->stringify;
    }
    return $c->organization->stringify;
}

sub uri {
    my $s = shift;
    my $c = shift;
    my $opts = shift;
    my $route_name = $opts->{tab} || 'show';
    $route_name .= '_contributor';
    return $c->url_for($route_name) unless ref($s);
    return $c->url_for($route_name, { contributor_identifier => $s->id } );
}

sub as_tree {
    my $s = shift;
    my %a = @_;
    my $c = $a{c} or return $s->SUPER::as_tree(@_);
    my $p = $s->person;
    my $uri = $s->uri($c);
    my $href = $uri->clone->to_abs;
    if (my $fmt = $c->stash('format')) {
        $href .= ".$fmt";
    }

    my %h = (
            organization => $s->organization ? $s->organization->as_tree : undef,
            organization_uri => $s->organization ? $s->organization->uri($c) : undef,
            person_uri   => $p ? $p->uri($c) : undef,
            person_id    => $p ? $p->id : undef,
            person => ( $p ? $p->as_tree : {} ),
            id => $s->id,
            role_type_identifier => $s->role_type_identifier,
            uri => $uri,
            href => $href,
    );
    return \%h;
}

sub merge_into {
    my $s = shift;
    my %args = @_;
    my $new = $args{new};
    my $merge_on = $args{merge_on} ? $args{merge_on} :  0;
    my $audit_user = $args{audit_user};
    my $audit_note = $args{audit_note};

    # Construct our target Contributor object
    my $target;
    if ($merge_on eq 'person' ) {
        $target = Tuba::DB::Object::Contributor->new(
            role_type_identifier    => $s->role_type_identifier,
            organization_identifier => $s->organization_identifier,
            person_id               => $new->id,
        );
    } elsif ($merge_on eq 'organization' ) {
        $target = Tuba::DB::Object::Contributor->new(
            role_type_identifier    => $s->role_type_identifier,
            organization_identifier => $new->identifier,
            person_id               => $s->person_id,
        );
    } else {
        die "Contributor must be merged based on Person or Organization";
    }

    # Discover if this target Contributor already exists
    if ($target->load(speculative => 1)) {
        # Case 1:
        # Already a contributor record for this role + person + org on the target?
        # Assign all publication maps for '$s' to '$target' and remove '$s'
        # before:
        #     person 1 -- contributor 1 -- map entry -- publication 1
        #     person 2 -- contributor 2 -- map entry -- publication 2
        # after:
        #     person 1 --\                    /--- map entry -- publication 1  
        #                 --- contributor 3 --
        #     person 2 --/                    \--- map entry -- publication 2
        my $pc_maps = Tuba::DB::Object::PublicationContributorMap::Manager->get_objects(
            query => [ contributor_id => $s->id ]);
        for my $pub_contr_map (@$pc_maps) {
            $pub_contr_map->merge_into( new => $target->id, audit_user => $audit_user, audit_note => $audit_note );
        }
        $s->delete(audit_user => $audit_user, audit_note => $audit_note) or die $s->error;
    } else {
        # Case 2:
        # Easier, just use existing contributor record but our person id.
        # before:
        #      person 1 -- contributor 1 --- map entries -- publications
        # after:
        #      person 2 -- contributor 1 --- map entries -- publications
        if ( $merge_on eq 'person' ) {
            $s->person_id($new->id);
        } elsif ( $merge_on eq 'organization' ) {
            $s->organization_id($new->identifier);
        }
        $s->save(audit_user => $audit_user, audit_note => $audit_note) or die $s->error;
    }
    return 1;
}
1;
