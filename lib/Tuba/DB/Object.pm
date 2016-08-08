=head1 NAME

Tuba::DB::Object -- base class for objects.

=head1 METHODS

=cut

package Tuba::DB::Object;
use DBIx::Simple;
use Pg::hstore qw/hstore_encode hstore_decode/;
use Tuba::Log;
use Tuba::Util qw/elide_str human_duration/;
use Mojo::JSON qw/encode_json/;
use Tuba::DB::Object::Metadata;
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

sub uri_with_format {
    my $obj = shift;
    my $c = shift;
    my $uri = $obj->uri($c);
    my $format = $c->stash('format') or return $uri;
    return "$uri.$format";
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
    my $dbh = $db->dbh or die $db->error;
    $db->do_transaction( sub {
        my %non_pk_changes = %changes;
        my %pk_changes;
        for (keys %pk) {
            $pk_changes{$_} = delete $non_pk_changes{$_};
        }
        for (keys %non_pk_changes) {
            $object->$_($non_pk_changes{$_});
        }
        $dbh->do("set local audit.username = ?",{},$audit_user);
        $dbh->do("set local audit.note = ?",{},$audit_note) if $audit_note;
        $object->save(audit_user => $audit_user, audit_note => $audit_note);
        
        my $dbis = DBIx::Simple->new($dbh);
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
    Carp::confess("weird args") if @_ % 2;
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
    my $dbh = $self->db->dbh;
    my $state = $dbh->ping;
    return 0 if $state==4; # in failed transaction
    if ($state==3) {  # already in a transaction
        $dbh->do("set local audit.username = ?",{},$audit_user);
        $dbh->do("set local audit.note = ?",{},$audit_note) if $audit_note;
        $status = $self->SUPER::save(%args);
    } else { # not in a transaction
        $status = $self->db->do_transaction( sub {
                $dbh->do("set local audit.username = ?",{},$audit_user);
                $dbh->do("set local audit.note = ?",{},$audit_note) if $audit_note;
                $status = $self->SUPER::save(%args);
        });
    }
    unless ($status) {
        logger->warn("save failed, obj error : ".($self->error || 'none'));
        logger->warn("save failed, db error : ".($self->db->error || 'none'));
    }
    return $status;
}

sub delete {
    my $object = shift;
    my %args = @_;
    my $audit_user = $args{audit_user} or die "missing audit_user for $object";
    my $audit_note = $args{audit_note};
    my $replacement;
    my ($old_identifier) = $object->pk_values;
    if ($replacement = $args{replacement}) {
        my @pk = $replacement->pk_values;
        die "cannot replace composite key" if @pk != 1;
        if ($pk[0] eq [ $object->pk_values ]->[0]) {
            $object->error("cannot replace ".$object->meta->table." with itself ($pk[0])");
            return 0;
        }
    }
    my $table_name = $object->meta->table;
    my $db = $object->db;
    my $dbh = $db->dbh or die $db->error;
    $db->do_transaction( sub {
        $dbh->do("set local audit.username = ?",{},$audit_user);
        $dbh->do("set local audit.note = ?",{},$audit_note) if $audit_note;
        $object->merge_into(new => $replacement, audit_user => $audit_user, audit_note => $audit_note) if $replacement;
        $object->SUPER::delete(@_);
        }
    ) or do {
        $object->error($db->error) unless $object->error;
        return 0;
    };

    # Can't do this inside the transaction because audit changes are not visible
    # until the transaction completes.
    if ($replacement) {
        my ($new_identifier) = $replacement->pk_values;
        my @pk_fields = map $_->name, $object->meta->primary_key->columns;
        $dbh->do(<<SQL, {}, "$pk_fields[0]=>$new_identifier", $old_identifier) or die $dbh->errstr;
            update audit.logged_actions set changed_fields = ?::hstore
             where action='D' and table_name='$table_name' and row_data->'$pk_fields[0]' = ?
SQL
        }

    return 1;
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
    - a list of regions (iff with_regions is sent)
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
    my $with_regions = delete $a{with_regions}; # a large tree
    $a{deflate} = 0 unless exists($a{deflate});

    my $tree = $s->Rose::DB::Object::Helpers::as_tree(%a);
    if ($c && !$bonsai) {
        if (my $pub = $s->get_publication) {
            $tree->{parents} = [];
            for my $parent ($pub->get_parents) {
                my $pub = $parent->{publication};
                my $activity = $parent->{activity};
                push @{ $tree->{parents} }, {
                    relationship => $parent->{relationship},
                    publication_type_identifier => $pub->{publication_type_identifier},
                    activity_uri => ($activity ? $activity->uri($c) : undef ),
                    label => $pub->stringify,
                    url   => $pub->to_object->uri($c),
                    note  => $parent->{note},
                };
            }
            $tree->{files} = [ map $_->as_tree(@_), $pub->files ];
            $tree->{gcmd_keywords} = [ map $_->as_tree(@_), $pub->gcmd_keywords ] if $with_gcmd;
            $tree->{regions} = [ map $_->as_tree(@_), $pub->regions] if $with_regions;
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
    #when used for result counts, the objects are skeletal, and do not stringify, so use eval
    $tree->{display_name} = eval{$s->stringify(display_name => 1)} || undef;
    $tree->{type} = $s->meta->table;
    $tree->{results_count} = $s->{results_count} if defined $s->{results_count}; #only relevant to /search
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
            my ($ctrs, $role_count, $person_count) = $p->contributors_grouped;
            $tree->{contributors} = [ map $_->as_tree(c => $c), @$ctrs ];
            my $refs = $p->references;
            my $format = $c->stash('format');
            $format &&= ".$format";
            my $base = $c->req->url->base;
            $tree->{references} = [ map +{
                                            uri => "/reference/".$_->identifier,
                                            href => "$base/reference/".$_->identifier."$format"
                                        }, @$refs ];
        }
    }
    for my $k (keys %$tree) {
        next unless $tree->{$k};
        if (ref($tree->{$k}) eq 'DateTime::Duration') {
            $tree->{$k} = human_duration($tree->{$k});
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

# overload for text rendering
sub as_text {
    my $s = shift;
    my %cols = map { $_ => 1} $s->meta->columns;
    if ($cols{title} && $cols{doi} && $cols{url}) {
        if ($s->title && $s->doi && $s->url) {
            return sprintf('%s, <%s> (%s)', $s->title, $s->url, $s->doi);
        }
    }
    if ($cols{title} && $cols{url}) {
        if ($s->title && $s->url) {
            return sprintf('%s, <%s>', $s->title, $s->url);
        }
    }
    return $s->stringify;
}

sub reference_count {
    my $ch = shift;
    my $pub = $ch->get_publication or return 0;
    my $sql = q[select count(1) from publication_reference_map where publication_id = ?];
    my $dbs = DBIx::Simple->new($ch->db->dbh);
    my ($count) = $dbs->query($sql, $pub->id)->flat;
    return $count;
}

sub as_autocomplete_str {
    my $obj = shift;
    my $elide = shift || 80;
    my $table = shift || $obj->meta->table;
    return join ' ', "[".$table."]", ( map "{".$_."}", $obj->pk_values ), elide_str($obj->stringify,$elide);
}

sub as_gcid_str {
    my $obj = shift;
    my $c = shift;
    my $elide = shift || 80;
    my $table = shift || $obj->meta->table;
    return sprintf('%s : %s',$obj->uri($c), elide_str($obj->stringify,$elide));
}

sub new_from_flat {
    my $c = shift;
    my $str;
    # overload, e.g. see gcmdkeywords
    die "Don't know how to make a $c from a string";
}

sub all_orgs {
    my $c = shift;
    my %args = @_;
    my $pub = $c->get_publication or return;
    my $dbh = $c->db->dbh;
    my $role_regex = $args{role_regex};
    my $sth = $dbh->prepare(<<"SQL");
select
c.organization_identifier as identifier
from publication_contributor_map m
inner join contributor c on c.id = m.contributor_id
where m.publication_id=?
and c.organization_identifier is not null
@{[ $role_regex ? "and role_type_identifier ~ ?" : "" ]}
group by 1
order by min(m.sort_key)
SQL
    $sth->execute($pub->id, ($role_regex || ())) or die $dbh->errstr;
    my $rows = $sth->fetchall_arrayref({});
    my @orgs = map Tuba::DB::Object::Organization->new(identifier => $_->{identifier})->load, @$rows;
    return (wantarray ? @orgs : \@orgs);
}

sub all_people {
    my $c = shift;
    my %args = @_;
    my $pub = $c->get_publication or return;
    my $dbh = $c->db->dbh;
    my $role_regex = $args{role_regex};
    my $sth = $dbh->prepare(<<"SQL");
select
c.person_id as id
from publication_contributor_map m
inner join contributor c on c.id = m.contributor_id
where m.publication_id=?
@{[ $role_regex ? "and role_type_identifier ~ ?" : "" ]}
and c.person_id is not null
group by 1
order by min(m.sort_key)
SQL
    $sth->execute($pub->id, ($role_regex || ())) or die $dbh->errstr;
    my $rows = $sth->fetchall_arrayref({});
    my @people = map Tuba::DB::Object::Person->new(id => $_->{id})->load, @$rows;
    return (wantarray ? @people : \@people);
}

sub same_as {
    my $s = shift;
    my $t = shift;
    return encode_json( [ $s->pk_values ] ) eq encode_json( [ $t->pk_values ] );
}

sub meta_class {
    return "Tuba::DB::Object::Metadata";
}

1;

