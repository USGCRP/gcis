=head1 NAME

Tuba::DB::Object -- base class for objects.

=head1 METHODS

=cut

package Tuba::DB::Object;
use DBIx::Simple;
use Pg::hstore qw/hstore_encode hstore_decode/;
use Tuba::Log;
use base 'Rose::DB::Object';

use strict;
use warnings;

=head2 moniker, plural
    
    Singuler and plural monikers for this object type.

=cut

sub moniker {
    my $c = shift;
    return $c->meta->table;
}

sub plural {
    shift->moniker.'s';
}

# Override these in mixin classes, e.g. Tuba::DB::Mixin::Object::Chapter
sub stringify {
    my $s = shift;
    return scalar $s->pk_values;
}

sub sortkey {
    my $s = shift;
    return $s->{_sortkey} if defined($s->{_sortkey});
    $s->{_sortkey} = $s->stringify;
    return $s->{_sortkey};
}

sub pk_values {
    my $s = shift;
    my $delim = shift || '/';
    my @pk = map $_->accessor_method_name, $s->meta->primary_key->columns;
    my @vals = map $s->$_, @pk;
    return @vals if wantarray;
    return join $delim, @vals;
}

sub uri {
    my $s = shift;
    my $c = shift or die "missing controller for uri";
    my $opts = shift || {};
    my $route_name = $opts->{tab} || 'show';
    $route_name .= '_'.$s->meta->table;
    return $c->url_for($route_name) unless ref $s;

    my $table = $s->meta->table;

    my %pk = map {( $_ => $s->$_ )} $s->meta->primary_key_columns;
    return unless $c->app->routes->find($route_name);
    my %url_params;
    for my $column_name (keys %pk) {
        my $param_name = $column_name;
        $param_name = $table.'_identifier' if $column_name eq 'identifier'; 
        $param_name = $param_name.'_identifier' if $column_name !~ /identifier/;
        $url_params{$param_name} = $pk{$column_name};
    }
    return $c->url_for( $route_name, \%url_params );
}

# https://groups.google.com/forum/?fromgroups#!searchin/rose-db-object/update$20primary$20key/rose-db-object/f8evi1dhp7c/IPhUUFS9aiEJ
sub update_primary_key {
    my $object = shift;
    my %changes = @_;
    my $audit_user = delete $changes{audit_user} or do {
        Carp::confess "missing audit user in update_primary_key";
    };
    my $audit_note = delete $changes{audit_note}; # Optional

    # Current pk values.
    my %pk;
    for my $pk_col ($object->meta->primary_key_columns) {
        # use ->name, rather than accessor_method_name to be consistent with %changes.
        my $acc = $pk_col->name;
        $pk{$pk_col->name} = $object->$acc;
    }

    # %changes should just be source_column -> new_value.
    my $table = $object->meta->table;
    my $db = $object->db;
    $db->do_transaction( sub {
        $db->dbh->do("set local audit.username = ?",{},$audit_user);
        $db->dbh->do("set local audit.note = ?",{},$audit_note) if $audit_note;
        my %non_pk_changes = %changes;
        my %pk_changes;
        for (keys %pk) {
            $pk_changes{$_} = delete $non_pk_changes{$_};
        }
        for (keys %non_pk_changes) {
            $object->$_($non_pk_changes{$_});
        }
        $object->save(audit_user => $audit_user, audit_note => $audit_note);
        
        my $dbis = DBIx::Simple->new($db->dbh);
        $dbis->update(qq["$table"], \%pk_changes, \%pk) or die $dbis->error;
    } ) or do {
        $object->error($db->error) unless $object->error;
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

sub get_publication {
    my $self = shift;
    die "not an object" unless ref($self);
    my %args = @_;
    my $types = Tuba::DB::Object::PublicationType::Manager->get_objects({table => $self->meta->table});
    return unless $types && @$types==1;
    my $type = $types->[0];
    my %pk = map {( $_ => $self->$_ )} $self->meta->primary_key_columns;
    my $pub = Tuba::DB::Object::Publication->new(
        publication_type_identifier => $type->identifier,
        fk                          => hstore_encode( \%pk )
    );
    if ($pub->load(speculative => 1)) {
        return $pub;
    }
    return unless $args{autocreate};
    return $pub;
}

sub find_or_make {
    my $class = shift;
    die "find_or_make not implemented for $class";
}

sub make_identifier {
    my $class = shift;
    my %args = @_;
    return $args{doi} if $args{doi};
    my $str = $args{name} or die "need doi or name to make an identifier";
    my $abbrev = $args{abbrev};
    my $max_length = $args{max_length} || 100;
    my $min_length = $args{min_length} || 3;
    my $exclude_short = $args{exclude_short} || 0;
    $exclude_short = 1 if $abbrev;

    my @words = split /\s+/, $str;
    my $id = '';
    my $next;
    while (length($id) < $max_length && defined($next = shift @words)) {
        my $stop;
        $next = lc $next;
        $stop = 1 if $next eq ':';
        $stop = 1 if $next =~ /[:]$/;
        $stop = 1 if $next =~ /[.]$/ && $next !~ /[.](?!$)/;
        $next =~ tr/a-z0-9-//dc;
        next if $exclude_short && $next =~ /^(a|the|from|and|for|to|with|of)$/;
        next unless length($next);
        if ($abbrev) {
            if ($next =~ /^\d+$/) {
                $id .= $next ;
            } else {
                $id .= substr($next,0,1);
            }
        } else {
            $id .= '-' if length($id);
            $id .= $next;
        }
        last if $stop && length($id) > $min_length;
    }
    die "could not make an identifier for $str" unless $id;
    return $id;
}

=head2 as_tree

Override Rose::DB::Object::Helpers::as_tree, and provide more
information :

    - a list of parent publications
    - a list of files
    - a list of gcmd keywords (iff with_gcmd is sent)
    - a list of contributors (if this is a publication)
    - a list of publications for each contributor record (if this is a contributor)

The parameter 'c' should have a controller object
(so that we can look up a URL for an object).

Pass the parameter bonsai => 1 to make a little tree
without the stuff above.

=cut

sub as_tree {
    my $s = shift;
    my %a = @_;
    my $c = $a{c}; # controller object
    my $bonsai = delete $a{bonsai}; # a small tree
    my $with_gcmd = delete $a{with_gcmd}; # a large tree
    $a{deflate} = 0 unless exists($a{deflate});

    my $tree = $s->Rose::DB::Object::Helpers::as_tree(%a);
    if ($c && !$bonsai) {
        if (my $pub = $s->get_publication) {
            $tree->{parents} = [];
            for my $parent ($pub->get_parents) {
                my $pub = $parent->{publication};
                push @{ $tree->{parents} }, {
                    relationship => $parent->{relationship},
                    publication_type_identifier => $pub->{publication_type_identifier},
                    label => $pub->stringify,
                    url   => $pub->to_object->uri($c),
                };
            }
            $tree->{files} = [ map $_->as_tree(@_), $pub->files ];
            $tree->{gcmd_keywords} = [ map $_->as_tree(@_), $pub->gcmd_keywords ] if $with_gcmd;
        }
        my $uri = $s->uri($c);
        my $href = $uri->clone->to_abs;
        if (my $fmt = $c->stash('format')) {
            $href .= ".$fmt";
        }
        $tree->{uri} //= $uri;
        $tree->{href} //= $href;
    }
    $tree->{uri} //= $s->uri($c) if $c;
    for my $k (keys %$tree) {
        delete $tree->{$k} if $k =~ /^_/;
    }
    if ($c && !$bonsai && $tree->{contributors}) {
        for my $t (@{ $tree->{contributors} }) {
            $t->{publications} = [ map {uri => $_->to_object->uri($c)}, Tuba::DB::Object::Contributor->new(id => $t->{id})->load->publications ];
        }
    }
    if ($c && !$bonsai) {
        if (my $p = $s->get_publication) {
            my @ctrs = $p->contributors;
            $tree->{contributors} = [ map +{uri => $_->uri($c)}, @ctrs ];

            my $refs = Tuba::DB::Object::Subpubref::Manager->get_objects(query => [ publication_id => $p->id ], limit => 200 );
            my $format = $c->stash('format');
            $format &&= ".$format";
            my $base = $c->req->url->base;
            $tree->{references} = [ map +{
                                            uri => "/reference/".$_->reference_identifier,
                                            href => "$base/reference/".$_->reference_identifier."$format"
                                        }, @$refs ];
        }
    }
    return $tree;
}

sub new_from_autocomplete {
    # See Tuba::Search.
    my $class = shift;
    my $str = shift or return;
    my @match =
        $str =~ /^
                   \[
                       ( [^]]+ )
                   \]
                   (?:\ \{
                       ( [^}]+ )
                      \}
                   )
                   (?:\ \{
                       ( [^}]+ )
                      \}
                   )?
                   (?:\ \{
                       ( [^}]+ )
                      \}
                   )?
                   (?: [^}]* )$
                  /x or return;
    my $table = shift @match;
    return unless $table;
    return unless $table eq $class->meta->table;
    my @keys = @match;
    my @pks = $class->meta->primary_key_column_names;
    my %new;
    @new{@pks} = @keys;
    my $obj = $class->new( %new );
    $obj->load(speculative => 1) or return;
    return $obj;
}

sub new_from_reference {
    my $class = shift;
    my $ref = shift;
    # Override to try to make a new object from the attrs in a Tuba::DB::Object::Reference.
    return;
}

sub keywords {
    my $c = shift;
    my $pub = $c->get_publication or return;
    return $pub->gcmd_keywords;
}

sub is_publication {
    my $s = shift;
    my $class = ref $s || $s;
    our %_cache;

    $_cache{ $class } //= Tuba::DB::Object::PublicationType::Manager->get_objects_count(query => [table => $s->meta->table]);
    return $_cache{ $class };
}


1;

