package Tuba::DB::Object::Organization;
use Tuba::Log;
use strict;

sub prov_type {
    my $self = shift;
    return sprintf(q[http://www.w3.org/ns/prov#%s], ucfirst($self->meta->table) );
}

sub foaf_type {
    my $self = shift;
    return sprintf(q[http://xmlns.com/foaf/0.1/%s], ucfirst($self->meta->table) );
}

sub find_or_make {
    my $class = shift;
    my %args = @_;
    my $name = $args{name} || 'Unknown Orgnanization';
    my $manager = join '::', $class, 'Manager';
    my $found = $manager->get_objects(query => [name => { ilike => $name} ], limit => 5 );
    my $org;
    if (@$found && @$found==1) {
        $org = $found->[0];
    } else {
        $org = $class->new(name => $name, identifier => $class->make_identifier(name => $name));
        if ($org->load(speculative => 1) ){
            if ($name ne $org->name) {
                logger->warn("Matched orgs : $name\n".$org->name);
            }
        }
        $org->save(%{ $args{audit} || {} }) or do { warn $org->error; return; };
    }
    return $org;
}

sub stringify {
    my $s = shift;
    return $s->name || $s->identifier;
}

1;

