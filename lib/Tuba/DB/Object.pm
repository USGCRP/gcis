package Tuba::DB::Object;
use DBIx::Simple;
use Tuba::Log;
use base 'Rose::DB::Object';

use strict;
use warnings;

sub plural {
    shift->meta->table.'s';
}

sub load_foreign {
    # Load foreign information (for data not represented by a foreign key in the schema);
    die "virtual method";
}

# Override these in mixin classes, e.g. Tuba::DB::Mixin::Object::Chapter
sub stringify {
    my $s = shift;
    my @pk = map $_->accessor_method_name, $s->meta->primary_key->columns;
    return join '/', map $s->$_, @pk;
}

sub uri {
    my $s = shift;
    my $c = shift;
    my @pk = map $_->accessor_method_name, $s->meta->primary_key->columns;
    return unless @pk==1;
    my $pk = $pk[0];
    my $route_name = 'show_'.$s->meta->table;
    return unless $c->app->routes->find($route_name);
    my $report_identifier = $c->default_report_identifier;
    return $c->url_for( $route_name, { $s->meta->table.'_identifier' => $s->$pk, report_identifier => $report_identifier } );
}

# https://groups.google.com/forum/?fromgroups#!searchin/rose-db-object/update$20primary$20key/rose-db-object/f8evi1dhp7c/IPhUUFS9aiEJ
sub update_primary_key {
    my $object = shift;
    my %changes = @_;
    my $audit_user = delete $changes{audit_user} or do {
        Carp::confess "missing audit user in update_primary_key";
    };
    my $audit_note = delete $changes{audit_note}; # Optional

    # Save current pk values in case there is a composite primary key and
    # we are only changing one piece.
    my %pk;
    for my $pk_col ($object->meta->primary_key_columns) {
        # use ->name, rather than accessor_method_name to be consistent with %changes.
        my $acc = $pk_col->name;
        $pk{$pk_col->name} = $object->$acc;
    }

    # %changes should just be source_column -> new_value.
    my $table = $object->meta->table;
    my %where;
    for my $col (keys %changes) {
        $where{$col} = $object->$col;
    }
    my $db = $object->db;
    $db->do_transaction( sub {
        $db->dbh->do("set local audit.username = ?",{},$audit_user);
        $db->dbh->do("set local audit.note = ?",{},$audit_note) if $audit_note;
        my $dbis = DBIx::Simple->new($db->dbh);
        $dbis->update($table, \%changes, \%where) or die $dbis->error;
    } ) or do {
        $object->error($db->error);
        return;
    };
    my $class = ref $object;
    my $replacement = $class->new( %pk, %changes )->load(speculative => 1);
    $replacement->db($object->db);
    return $replacement;
}

our $_audit_user;
our $_audit_note;
sub _am_recursing { # am I recursing?
    my $i = 1;
    my %seen;
    my ($lastpkg,$lastfile,$lastline,$lastsub) = caller $i;
    while (my @c = caller ++$i) {
        my ($package,$file,$line,$sub) = @c;
        return 1 if $sub eq $lastsub;
    }
    return 0;
}
sub save {
    my $self = shift;
    my %args = @_;
    my $status;
    # This function will be called several times during a nested save (e.g. $figure->add_image(..) ).
    # But %args are not propogated.  So, store $audit_info in a package var which we use
    # if and only if this function is part of the call stack.
    my $audit_user = delete $args{audit_user};
    my $audit_note = delete $args{audit_note}; # Optional
    if (!$audit_user && $_audit_user && _am_recursing()) {
        $audit_user = $_audit_user;
        $audit_note = $_audit_note;
    }

    Carp::confess "missing audit user in save" unless $audit_user;
    $_audit_user = $audit_user;
    $_audit_note = $audit_note;
    $self->meta->error_mode('fatal');
    $status = $self->db->do_transaction( sub {
            $self->db->dbh->do("set local audit.username = ?",{},$audit_user);
            $self->db->dbh->do("set local audit.note = ?",{},$audit_note) if $audit_note;
            $self->SUPER::save(%args);
    } );
    unless ($status) {
        logger->warn("save failed, obj error : ".($self->error || 'none'));
        logger->warn("save failed, db error : ".($self->db->error || 'none'));
    }
    return $status;
}

sub prov_type {
    my $self = shift;
    return q[http://www.w3.org/ns/prov#Entity];
}

sub foaf_type {
    my $self = shift;
    return;
}

sub prov_label {
    my $self = shift;
    return $self->name if $self->can('name');
    return $self->title if $self->can('title');
    return $self->statement if $self->can('statement');
    return $self->identifier;
}

sub foaf_name {
    my $self = shift;
    return $self->name if $self->can('name');
    return $self->title if $self->can('title');
    return $self->statement if $self->can('statement');
    return $self->identifier;
}

sub thumbnail {
    my $self = shift;
    my $c = shift;
    # overload if you can generate a thumbnail image
    return "";
}

sub get_publication {
    my $self = shift;
    my %args = @_;
    my $table = $self->meta->table;
    # TODO am assuming table==identifier for now
    my $type = Tuba::DB::Object::PublicationType->new(identifier => $table)->load(speculative => 1) or return;
    return unless $self->can('identifier');
    my $pub = Tuba::DB::Object::Publication->new(publication_type => $type->identifier, fk => $self->identifier);
    if ($pub->load(speculative => 1)) {
        return $pub;
    }
    return unless $args{autocreate};
    return Tuba::DB::Object::Publication->new(publication_type => $type->identifier, fk => $self->identifier);
}

1;

