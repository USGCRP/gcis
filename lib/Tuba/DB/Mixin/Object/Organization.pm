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
        tr/a-zA-Z0-9-//dc for @words;
        $_ = lc $_ for @words;
        my $identifier = @words ?  (join '-', @words) : "unknown-".rand;
        $identifier =~ s/--/-/g;
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

sub reports {
    my $s = shift;
    my $list = Tuba::DB::Object::Publication::Manager->get_objects(
        query => [ organization_identifier => $s->identifier, publication_type_identifier => 'report' ],
        with_objects => [qw/contributors/] );
    my @reports = map $_->to_object, @$list;
    return @reports;
}

sub merge_into {
    my $s = shift;
    my %args = @_;
    my $new = $args{new};
    my $audit_user = $args{audit_user};
    my $audit_note = $args{audit_note};

    # ids for other contributors
    my $contributors = Tuba::DB::Object::Contributor::Manager->get_objects( query => [ organization_identifier => $s->id ] );
    for my $contributor ( @$contributors ) {
        my $success = $contributor->merge_into(
                new => $new,
                merge_on => 'organization',
                audit_user => $audit_user,
                audit_note => $audit_note,
        );
        die "Cannot merge Organizations" unless $success;
    }
    return 1;
}

1;

