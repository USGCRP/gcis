package Tuba::DB::Object::Contributor;
use strict;

sub stringify {
    my $c = shift;
    my $person = $c->person;
    my $org = $c->organization_obj;
    my $role =  $c->role_type;
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

1;
