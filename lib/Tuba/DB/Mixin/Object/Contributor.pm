package Tuba::DB::Object::Contributor;
use strict;

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

1;
