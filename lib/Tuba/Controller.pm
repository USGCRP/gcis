=head1 NAME

Tuba::Controller -- base class for controllers.

=cut

package Tuba::Controller;
use Mojo::Base qw/Mojolicious::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use Rose::DB::Object::Util qw/unset_state_in_db/;
use List::Util qw/shuffle/;
use Tuba::Search;
use Pg::hstore qw/hstore_encode/;

=head2 check, list

These virtual methods should be implemented by subclasses.

=cut

sub check { die "not implemented" };
sub list { die "not implemented" };

=head2 show

Subclasses should override this but may call it for rendering,
after setting 'object' and 'meta'.

=cut

sub show {
    my $c = shift;

    my $object = $c->stash('object') or die "no object";
    my $meta  = $c->stash('meta') or die "no meta";
    my $table = $meta->table;

    $c->respond_to(
        json  => sub { my $c = shift;
                       $c->render_maybe(template => "$table/object")
                    or $c->render(json => $object->as_tree ); },
        nt    => sub { my $c = shift;
                      $c->render_maybe(template => "$table/object")
                   or $c->render(template => "object") },
        html  => sub { my $c = shift;
                     $c->render_maybe(template => "$table/object")
                   or $c->render(template => "object") }
    );
};

=head2 select

Called as a bridge, e.g. for /report/:report_identifier/figure/:figure_identifier

=cut

sub select {
    my $c = shift;
    my $loaded = $c->_this_object;
    if ($loaded) {
        my $table = $loaded->meta->table;
        $c->stash($table => $loaded);
        return 1;
    }
    $c->render_not_found;
    return 0;
}

sub _guess_object_class {
    my $c = shift;
    my $class = ref $c;
    my ($object_class) = $class =~ /::(.*)$/;
    $object_class = 'Tuba::DB::Object::'.$object_class;
    $object_class->can('meta') or die "can't figure out object class for $class (not $object_class)";
    return $object_class;
}

=head2 create_form

Create a default form.  If this is overriden by a subclass,
the template in <table>/create_form.html.ep will be used automatically,
instead of the default create_form.html.ep.

=cut

sub create_form {
    my $c = shift;
    my $controls = $c->stash('controls') || {};
    $c->stash(controls => { $c->_default_controls, %$controls } );
    $c->stash(meta => $c->_guess_object_class->meta);
    $c->render(template => "create_form");
}

sub _redirect_to_view {
    my $c = shift;
    my $object = shift;

    my $table = $object->meta->table;
    if ($object->can('identifier')) {
        return $c->redirect_to("show_$table", $table.'_identifier' => $object->identifier );
    }
    $c->app->log->warn("no identifier column cannot find view page for $object");
    return $c->render(text => "created new ".$object->table);
}

=head2 create

Generic create.  See above for overriding.

=cut

sub create {
    my $c = shift;
    my $class = ref $c;
    my ($object_class) = $class =~ /::(.*)$/;
    $object_class = 'Tuba::DB::Object::'.$object_class;
    my %obj;
    if (my $json = $c->req->json) {
        %obj = %$json;
    } else {
        for my $col ($object_class->meta->columns) {
            my $got = $c->param($col->name);
            $obj{$col->name} = defined($got) && length($got) ? $got : undef;
        }
    }
    if (exists($obj{report}) && $c->stash('report_identifier')) {
        $obj{report} = $c->stash('report_identifier');
    }
    my $new = $object_class->new(%obj);
    $new->meta->error_mode('return');
    my $table = $object_class->meta->table;
    $new->save(audit_user => $c->user) and return $c->_redirect_to_view($new);
    $c->respond_to(
        json => sub {
                my $c = shift;
                $c->app->log->warn("# rendering");
                $c->res->code(409);
                $c->render(json => { error => $new->error } );
            },
        html => sub {
                my $c = shift;
                $c->flash(error => $new->error);
                $c->redirect_to("create_form_$table");
            }
        );
}

sub _this_object {
    my $c = shift;
    my $object_class = $c->_guess_object_class;
    my $meta = $object_class->meta;
    my %pk;
    for my $name ($meta->primary_key_column_names) { ; # e.g. identifier, report
        my $stash_name = $name;
        $stash_name = $meta->table.'_'.$name if $name eq 'identifier';
        $stash_name .= '_identifier' unless $stash_name =~ /identifier/;
        my $val = $c->stash($stash_name) or do {
            $c->app->log->warn("No values for $name when loading $object_class");
            return;
        };
        $pk{$name} = $val;
    }

    my $object = $object_class->new(%pk)->load(speculative => 1);
    return $object;
}

sub _chaplist {
    my $rpt = shift;
    my @chapters = @{ Chapters->get_objects(query => [ report => $rpt ], sort_by => 'number') };
    return [ '', map [ sprintf( '%s %s', ( $_->number || '' ), $_->title ), $_->identifier ], @chapters ];
}
sub _default_controls {
    my $c = shift;
    return (
        chapter => sub { +{ template => 'select',
                             params => { values => _chaplist(shift->stash('report_identifier')) } } },
    );
}

=head2 update_form

Generic update_form.

=cut

sub update_form {
    my $c = shift;
    my $controls = $c->stash('controls') || {};
    $c->stash(controls => { $c->_default_controls, %$controls } );
    my $object = $c->_this_object or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $object->meta);
    $c->render(template => "update_form");
}

=head2 update_prov_form

Generic update_prov_form.

=cut

sub update_prov_form {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $object->meta);
    my $pub = $object->get_publication(autocreate => 1) or return $c->render(text => 'cannot make publication entry');
    $c->stash(publication => $pub);
    my $parents = [];
    if ($pub) {
        $parents = [ $pub->get_parents ];
    }
    $c->stash( parents => $parents );
    $c->render(template => "update_prov_form");
}

sub _text_to_object {
    my $c = shift;
    my $str = shift or return;
    return $c->Tuba::Search::autocomplete_str_to_object($str);
}

=head2 update_prov

Update the provenance for this object.

=cut

sub update_prov {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $object->meta);
    my $pub = $object->get_publication(autocreate => 1);
    $pub->save(changes_only => 1, audit_user => $c->user); # might be new.
    $c->stash(publication => $pub);
    $c->stash->{template} = 'update_prov_form';

    if (my $delete = $c->param('delete_publication')) {
        my $rel = $c->param('delete_relationship');
        my $other_pub = Publication->new(id => $delete)->load(speculative => 1);
        my $map = PublicationMap->new(child => $pub->id, parent => $delete, relationship => $rel);
        $map->load(speculative => 1) or return $c->render(error => "could not find relationship");
        $map->delete(audit_user => $c->user) or return $c->render(error => $map->error);
        $c->stash(info => "Deleted $rel ".($other_pub ? $other_pub->stringify : ""));
        return $c->render;
    }

    my $parent_str = $c->param('parent') or return $c->render;
    my $rel = $c->param('parent_rel')    or return $c->render(error => "Please select a relationship");
    my $parent = $c->_text_to_object($parent_str) or return $c->render(error => 'cannot parse publication');
    my $parent_pub = $parent->get_publication(autocreate => 1);
    $parent_pub->save(changes_only => 1, audit_user => $c->user) or return $c->render(error => $pub->error);

    my $map = PublicationMap->new(
        child        => $pub->id,
        parent       => $parent_pub->id,
        relationship => $rel,
        note         => ( ($c->param('note') || undef) ),
    );

    $map->save(audit_user => $c->user) or return $c->render(error => $map->error);

    $c->stash(info => "Saved $rel : ".$parent_pub->stringify);
    return $c->render;
}

=head2 update_rel_form

Form for updating the relationships.

=cut

sub update_rel_form {
    my $c = shift;
    # TODO
    my $object = $c->_this_object;
    my $meta = $object->meta;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    $c->render(template => "update_rel_form");
}

=head2 update_rel

Update the relationships.

=cut

sub update_rel {
    my $c = shift;
    # TODO

}


=head2 update

Generic update for an object.

=cut

sub update {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    my %pk_changes;
    my $table = $object->meta->table;

    if ($c->param('delete')) {
        if ($object->delete) {
            $c->flash(message => "Deleted $table");
            return $c->redirect_to('list_'.$table);
        }
        $c->flash(error => $object->error);
        $c->redirect_to("update_form_".$object->meta->table);
    }

    for my $col ($object->meta->columns) {
        my $param = $c->param($col->name);
        $param = undef unless defined($param) && length($param);
        my $acc = $col->accessor_method_name;
        if ($col->is_primary_key_member && $param ne $object->$acc) {
            $pk_changes{$col->name} = $param;
            next;
        }
        $object->$acc($param);
    }

    $object->meta->error_mode('return');
    my $ok = 1;
    if (keys %pk_changes) {
        # See Tuba::DB::Object.
        if (my $new = $object->update_primary_key(audit_user => $c->user, %pk_changes)) {
            $new->$_($object->$_) for map { $_->is_primary_key_member ? () : $_->name } $object->meta->columns;
            $object = $new;
        } else {
            $ok = 0;
        }
    }


    $ok = $object->save(changes_only => 1, audit_user => $c->user) if $ok;
    $ok and return $c->_redirect_to_view($object);
    $c->flash(error => $object->error);
    $c->redirect_to("update_form_".$table);
}

=head2 remove

Generic delete

=cut

sub remove {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    $object->delete or return $c->render_exception($object->error);
    return $c->render(text => 'ok');
}

=head2 index

Handles / for tuba.

=cut

sub index {
    my $c = shift;
    state $count;
    unless ($count) {
        $count = Files->get_objects_count;
    }
    my $offset = int rand ($count - 50);
    $offset = 0 if $offset < 0;

    my $demo_files = Files->get_objects(
            require_objects => [qw/image_obj.figure_objs.chapter_obj/],
            offset => $offset,
            limit => 50,
        );
    my %uniq;
    for (@$demo_files) {
        $uniq{$_->file} //= $_;
    }
    $c->stash(demo_files => [ shuffle values %uniq ]);
    $c->render(template => 'index');
}

=item history

Generic history of changes to an object.

[ 'audit_username', 'audit_note', 'table_name', 'changed_fields', 'action_tstamp_tx', 'action' ],

=cut

sub history {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    my $pk = $object->meta->primary_key;
    my @columns = $pk->column_names;

    my %bind  = map {( "pkval_$_" => $object->$_ )} @columns;
    my $where = join ' and ', map qq{ row_data->'$_' = :pkval_$_ }, @columns;
    # TODO: also look for pk changes in changed_fields->'$pk' = :pkval_$pk) };
    my $result = $c->dbc->select(
        [ '*', 'extract(epoch from action_tstamp_tx) as sort_key' ],
        table => "audit.logged_actions",
        where => [ $where, \%bind ],
        append => 'order by action_tstamp_tx desc',
    );
    my $change_log = $result->all;

    # Also look for provenance changes.
    if (my $pub = $object->get_publication) {
        my $id = $pub->id;
        my $more = $c->dbc->select(
            [ '*', 'extract(epoch from action_tstamp_tx) as sort_key' ],
            table  => "audit.logged_actions",
            where  => [ "row_data->'child' = :id", { id => $id } ],
            append => 'order by action_tstamp_tx desc',
        );

        $change_log = [ @{ $more->all }, @$change_log ];
        @$change_log = sort { $b->{sort_key} cmp $a->{sort_key} } @$change_log;
    }

    $c->render(template => 'history', change_log => $change_log, object => $object, pk => $pk)
}


1;
