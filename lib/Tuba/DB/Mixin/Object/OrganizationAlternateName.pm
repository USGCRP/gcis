package Tuba::DB::Object::OrganizationAlternateName;
use strict;

sub stringify {
    my $c = shift;
    return $c->alternate_name
        || $c->organization_identifier
        || $c->SUPER::stringify(@_);
}

1;

