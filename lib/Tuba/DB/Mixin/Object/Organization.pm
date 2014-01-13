package Tuba::DB::Object::Organization;
use Tuba::Log;
use strict;

sub insert {
    my $s = shift;
    unless (defined $s->identifier) {
        my $name = $s->name;
        my %skip = map { $_ => 1} qw/
                a an the and or nor for but so yet to of by at for but in with has
        /;
        my @words = grep { !$skip{lc $_} } split / /, $name;
        my $identifier = @words ?  (join '', map lc(substr($_,0,1)), @words) : "unknown-".rand;
        $s->identifier($identifier);
    }
    return $s->SUPER::insert(@_);
};

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

sub type {
    my $s = shift;
    my $t = $s->organization_type or return "";
    return $t->identifier;
}

sub people {
    my $s = shift;
     my %seen;
     for my $c (@{ $s->contributors }) {
         my $person = $c->person or next;
         next if $seen{$person->id};
         $seen{$person->id} = $person;
     }
     return values %seen;
}


1;

