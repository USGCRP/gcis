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
    my $contributors = Tuba::DB::Object::Contributor::Manager->get_objects( query => [ person_id => $s->id ] );
    for my $contributor ( @$contributors ) {
        $contributor->merge_into(
                new => $new,
                merge_on => 'person',
                audit_user => $audit_user,
                audit_note => $audit_note,
        );
    }
    return 1;
}

1;
