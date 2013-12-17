package Tuba::DB::Object::Person;
use strict;

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

1;
