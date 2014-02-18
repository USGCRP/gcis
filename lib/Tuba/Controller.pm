=head1 NAME

Tuba::Controller -- base class for controllers.

=cut

package Tuba::Controller;
use Mojo::Base qw/Mojolicious::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use Rose::DB::Object::Util qw/unset_state_in_db/;
use List::Util qw/shuffle/;
use Tuba::Search;
use Pg::hstore qw/hstore_encode hstore_decode/;
use Path::Class qw/file/;
use Tuba::Log;
use Tuba::Util qw/nice_db_error show_diffs/;
use File::Temp;
use YAML::XS qw/Dump/;
use Data::Dumper;

=head2 list

Generic list.

Override make_tree_for_list in order to generate a representation of each
object for a list.

=cut

sub make_tree_for_list {
    my $c = shift;
    my $obj = shift;
    my %t;
    for my $method (@{ $obj->meta->column_accessor_method_names }) {
        $t{$method} = $obj->$method;
    }
    my $uri = $obj->uri($c);
    my $href = $uri->clone->to_abs;
    $href .= '.'.$c->stash('format') if $c->stash('format');
    $t{uri} = $uri;
    $t{href} = $href;
    return \%t;
}

sub common_tree_fields {
    my $c = shift;
    my $obj = shift;
    my $uri = $obj->uri($c);
    my $href = $uri->clone->to_abs;
    if (my $fmt = $c->stash('format')) {
        $href .= ".$fmt";
    }
    return ( uri => $uri, href => $href );
}

sub list {
    my $c = shift;
    my $objects = $c->stash('objects');
    my $all = $c->param('all') ? 1 : 0;
    unless ($objects) {
        my $manager_class = $c->stash('manager_class') || $c->_guess_manager_class;
        $objects = $manager_class->get_objects(sort_by => "identifier", $all ? () : (page => $c->page, per_page => $c->per_page));
        $c->set_pages($manager_class->get_objects_count) unless $all;
    }
    my $object_class = $c->stash('object_class') || $c->_guess_object_class;
    my $meta = $object_class->meta;
    my $table = $meta->table;
    my $template = $c->param('thumbs') ? 'thumbs' : 'objects';
    my %tree;

    $c->respond_to(
        yaml => sub {
            my $c = shift;
            if (my $page = $c->stash('page')) {
                $c->res->headers->accept_ranges('page');
                $c->res->headers->content_range(sprintf('page %d/%d',$page,$c->stash('pages')));
            }
            # Trees are smaller when getting all objects.
            $c->render_yaml([ map $c->make_tree_for_list($_), @$objects ]) },
        json => sub {
            my $c = shift;
            if (my $page = $c->stash('page')) {
                $c->res->headers->accept_ranges('page');
                $c->res->headers->content_range(sprintf('page %d/%d',$page,$c->stash('pages')));
            }
            # Trees are smaller when getting all objects.
            $c->render(json => [ map $c->make_tree_for_list($_), @$objects ]) },
        html => sub {
             my $c = shift;
             $c->render_maybe(template => "$table/$template", meta => $meta, objects => $objects )
                 or
             $c->render(template => $template, meta => $meta, objects => $objects )
         }
    );
};

sub _stringify {
    my $what = shift;
    return $what unless ref $what;
    for (ref $what) {
        /ARRAY/ and return [ map _stringify($_), @$what ];
        /HASH/ and return { map { $_ => _stringify($what->{$_}) } keys %$what };
    }
    return "$what";
}

sub render_yaml {
    my $c = shift;
    my $thing = shift;
    $c->res->headers->content_type('text/x-yaml; charset=utf-8');
    my $stringified = _stringify($thing);
    $c->res->body(Dump($stringified));
    $c->rendered;
}

=head2 show

Subclasses should override this but may call it for rendering,
after setting 'object' and 'meta'.

Override make_tree_for_show to make a datastructure to serialize
for showing.

=cut

sub make_tree_for_show {
    my $c = shift;
    my $obj = shift;
    return $obj->as_tree(c => $c,
        ( $c->param('brief') ? (bonsai => 1) : ()),
        ( $c->param('with_gcmd') ? (with_gcmd => 1) : ())
    );
}


sub show {
    my $c = shift;

    my $object = $c->stash('object') or die "no object";
    my $meta  = $c->stash('meta') || $object->meta;
    $c->stash(meta => $meta) unless $c->stash('meta');
    my $table = $meta->table;
    $c->stash(relationships => $c->_order_relationships(meta => $meta));
    $c->stash(cols => $c->_order_columns(meta => $object->meta));

    $c->respond_to(
        yaml  => sub { my $c = shift; $c->render_maybe(template => "$table/object") or $c->render_yaml($c->make_tree_for_show($object) ); },
        json  => sub { my $c = shift; $c->render_maybe(template => "$table/object") or $c->render(json => $c->make_tree_for_show($object)); },
        ttl   => sub { my $c = shift; $c->render_maybe(template => "$table/object") or $c->render(template => "object") },
        html  => sub { my $c = shift; $c->render_maybe(template => "$table/object") or $c->render(template => "object") },
        nt    => sub { shift->render_partial_ttl_as($table,'ntriples'); },
        rdfxml=> sub { shift->render_partial_ttl_as($table,'rdfxml'); },
        dot   => sub { shift->render_partial_ttl_as($table,'dot'); },
        rdfjson => sub { shift->render_partial_ttl_as($table,'json'); },
        jsontriples => sub { shift->render_partial_ttl_as($table,'json-triples'); },
        svg   => sub {
            my $c = shift;
            $c->res->headers->content_type('image/svg+xml');
            $c->render_partial_ttl_as($table,'svg'); },
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

sub _guess_manager_class {
    my $c = shift;
    my $class = ref $c;
    my ($object_class) = $class =~ /::(.*)$/;
    $object_class = 'Tuba::DB::Object::'.$object_class;
    $object_class->can('meta') or die "can't figure out object class for $class (not $object_class)";
    return $object_class.'::Manager';
}


=head2 create_form

Create a default form.  If this is overriden by a subclass,
the template in <table>/create_form.html.ep will be used automatically,
instead of the default create_form.html.ep.

=cut

sub create_form {
  my $c = shift;
  my $controls = $c->stash('controls') || {};
  $c->stash(controls => {$c->_default_controls, %$controls});
  my $object_class = $c->_guess_object_class;
  my $table        = $object_class->meta->table;
  $c->stash(object_class => $object_class);
  $c->stash(meta         => $object_class->meta);
  $c->stash(cols => $c->_order_columns(meta => $object_class->meta));
  $c->render_maybe(template => "$table/create_form")
    or $c->render(template => "create_form");
}

sub _default_order {
  return qw/report_identifier chapter_identifier identifier number ordinal
    title description caption statement lat_min lat_max lon_min lon_max time_start time_end/;
}

sub _order_columns {
    # Default ordering; use heuristics to put things first
    my $c = shift;
    my %a = @_;
    my $meta = $a{meta};
    my @first = $c->_default_order;
    my @ordered;
    my %col_names = map { $_->name => $_ } $meta->columns;
    for my $name (@first, keys %col_names) {
        my $this = delete $col_names{$name} or next;
        push @ordered, $this;
    }
    return \@ordered;
}

sub _order_relationships {
    my $c = shift;
    my %a = @_;
    my $meta = $a{meta};
    my @first = qw/report reports chapter chapters/;
    my @ordered;
    my %rel_names = map { $_->name => $_ } $meta->relationships;
    for my $name (@first, keys %rel_names) {
        my $this = delete $rel_names{$name} or next;
        push @ordered, $this;
    }
    return \@ordered;
}


sub _redirect_to_view {
    my $c = shift;
    my $object = shift;
    my $url = $object->uri($c);
    $url->query->param(no_header => 1) if $c->param('no_header');
    return $c->redirect_to( $url );
}

=head2 create

Generic create.  See above for overriding.

=cut

sub create {
    my $c = shift;
    my $class = ref $c;
    my $object_class = $c->_guess_object_class;
    my $computed = $c->stash('computed_params') || {}; # to override incoming params in a subclass.
    my %obj;
    if (my $json = ($c->stash('object_json') || $c->req->json)) {
        %obj = %$json;
    } else {
        for my $col ($object_class->meta->columns) {
            my $got = $computed->{$col->name} // $c->param($col->name);
            $got = $c->normalize_form_parameter(column => $col->name, value => $got);
            $obj{$col->name} = defined($got) && length($got) ? $got : undef;
        }
    }
    my $audit_note = delete($obj{audit_note});
    if (exists($obj{report_identifier}) && $c->stash('report_identifier')) {
        $obj{report_identifier} = $c->stash('report_identifier');
    }
    my $new = $object_class->new(%obj);
    $new->meta->error_mode('return');
    my $table = $object_class->meta->table;
    $new->save(audit_user => $c->user, audit_note => $audit_note)
          and $c->post_create($new)
          and return $c->_redirect_to_view($new);
    $c->respond_to(
        json => sub {
                my $c = shift;
                $c->res->code($new->error =~ /(already exists|violates unique constraint)/ ? 409 : 500);
                $c->render(json => { error => $new->error } );
            },
        html => sub {
                my $c = shift;
                $c->flash(error => nice_db_error($new->error));
                my $url = $object_class->uri($c,{tab => "create_form"});
                $url->query->param(no_header => 1) if $c->param('no_header');
                $c->redirect_to($url);
            }
        );
}

sub post_create {
    my $c = shift;
    my $obj = shift;
    # override to do something after saving succesfully
    return 1;
}
sub post_update {
    my $c = shift;
    my $obj = shift;
    # override to do something after saving succesfully
    return 1;
}


sub _this_object {
    my $c = shift;
    my $object_class = $c->_guess_object_class;
    if (my $cached = $c->stash('_this_object')) {
        return $cached if ref($cached) eq $object_class;
    }
    my $meta = $object_class->meta;
    my %pk;
    for my $name ($meta->primary_key_column_names) { ; # e.g. identifier, report_identifier
        my $stash_name = $name;
        $stash_name = $meta->table.'_'.$name if $name eq 'identifier';
        $stash_name .= '_identifier' unless $stash_name =~ /identifier/;
        my $val = $c->stash($stash_name) or do {
            next;
        };
        $pk{$name} = $val;
    }

    my $object = $object_class->new(%pk)->load(speculative => 1);
    $c->stash(_this_object => $object);
    return $object;
}

sub _chaplist {
    my $c = shift;
    my $report_identifier = shift;
    my @chapters = @{ Chapters->get_objects(query => [ report_identifier => $report_identifier ], sort_by => 'number') };
    return [ '', map [ sprintf( '%s %s', ( $_->number || '' ), $_->title ), $_->identifier ], @chapters ];
}
sub _rptlist {
    my $c = shift;
    my @reports = @{ Reports->get_objects(sort_by => 'identifier') };
    return [ '', map [ sprintf( '%s : %.80s', ( $_->identifier || '' ), ($_->title || '') ), $_->identifier ], @reports ];
}
sub _default_controls {
    my $c = shift;
    return (
        organization_identifier => sub {
            my $c = shift;
            { template => 'autocomplete', params => { object_type => 'organization' } }
        },
        chapter_identifier => sub { my $c = shift;
                            +{ template => 'select',
                               params => { values => $c->_chaplist($c->stash('report_identifier')) } } },
        report_identifier  => sub { +{ template => 'select',
                                params => { values => shift->_rptlist() } } },
    );
}

sub _default_rel_controls {
    my $c = shift;
    return (
    chapter => sub { my ($c,$obj) = @_;
                         +{ template => 'select',
                            params => { values => $c->_chaplist($c->stash('report_identifier')),
                                        column => $obj->meta->column('chapter_identifier'),
                                        value => $obj->chapter_identifier }
                        } },
    report => sub { my ($c,$obj) = @_;
                      +{ template => 'select',
                         params => { values => $c->_rptlist(),
                                     column => $obj->meta->column('report_identifier'),
                                     value => $obj->report_identifier } } },
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
    $c->stash(cols => $c->_order_columns(meta => $object->meta));
    my $format = $c->detect_format;
    my $table = $object->meta->table;
    $c->respond_to(
        json => sub {
            my $c = shift;
            my $tree = $object->as_tree(max_depth => 0, bonsai => 1);
            return $c->render(json => $tree);
        },
        yaml => sub {
            my $c = shift;
            my $tree = $object->as_tree(max_depth => 0, bonsai => 1);
            return $c->render_yaml($tree);
        },
        html => sub {
            my $c = shift;
            $c->render_maybe(template => "$table/update_form")
                or $c->render(template => "update_form");
        }
    );
}

=head2 update_prov_form

Generic update_prov_form.

=cut

sub update_prov_form {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $object->meta);
    my $pub = $object->get_publication(autocreate => 1) or return $c->render(text => $object->meta->table.' is not a publication');
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
    $c->stash(tab => 'update_prov_form');
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
        $map->load(speculative => 1) or return $c->update_error("could not find relationship");
        $map->delete(audit_user => $c->user) or return $c->update_error($map->error);
        $c->stash(info => "Deleted $rel ".($other_pub ? $other_pub->stringify : ""));
        return $c->render;
    }
    my $json = $c->req->json;
    if ($json && (my $del = delete $json->{delete})) {
        my $uri = $del->{parent_uri} or return $c->update_error("missing parent_uri to delete");
        my $parent = $c->uri_to_obj($uri) or return $c->update_error("cannot find $uri");
        my $rel = $del->{parent_rel} or return $c->update_error("missing parent_rel");
        my $map = PublicationMap->new(
          child        => $pub->id,
          parent       => $parent->get_publication(autocreate => 1)->id,
          relationship => $rel
        );
        $map->load(speculative => 1) or return $c->update_error("relationship $rel $uri not found");
        $map->delete or return $c->update_error($map->error);
    }

    my ($parent_pub,$rel,$note);
    if ($json) {
        my $parent_uri  = $json->{parent_uri} or return $c->update_error("Missing parent_uri");
        my $parent      = $c->uri_to_obj($parent_uri) or return $c->update_error("Couldn't find $parent_uri");
        $parent_pub     = $parent->get_publication(autocreate => 1) or return $c->update_error("$parent_uri is not a publication");
        $parent_pub->save(audit_user => $c->user) unless $parent_pub->id;
        $rel  = $json->{parent_rel} or return $c->update_error("Missing parent_rel");
        $note = $json->{note};
    }  else {
        my $parent_str   = $c->param('parent') or return $c->render;
        my $parent       = $c->_text_to_object($parent_str) or return $c->render(error => 'cannot parse publication');
        $parent_pub      = $parent->get_publication(autocreate => 1);
        $parent_pub->save(changes_only => 1, audit_user => $c->user) or return $c->render(error => $pub->error);
        $rel  = $c->param('parent_rel')    or return $c->render(error => "Please select a relationship");
        $note = $c->param('note');
    }

    return $c->render unless $parent_pub;

    my $map = PublicationMap->new(
        child        => $pub->id,
        parent       => $parent_pub->id,
        relationship => $rel,
        note         => $note
    );

    $map->save(audit_user => $c->user) or return $c->update_error($map->error);
    $c->stash(info => "Saved $rel : ".$parent_pub->stringify);
    return $c->redirect_without_error;
}

=head2 update_rel_form

Form for updating the relationships.

Override this and set 'relationships' to relationships that should
be on this page, e.g.

    $c->stash(relationships => [ map Figure->meta->relationship($_), qw/images/ ]);

=cut

sub update_rel_form {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    my $controls = $c->stash('controls') || {};
    $c->stash(controls => { $c->_default_rel_controls, %$controls } );
    my $meta = $object->meta;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    my $table = $meta->table;
    $c->render_maybe(template => "$table/update_rel_form")
        or $c->render(template => "update_rel_form");
}

=head2 update_files_form

Form for updating files.

=cut

sub update_files_form {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $object->meta);
    $c->render(template => "update_files_form");
}

=head2 update_contributors_form

Form for updating contributors.

=cut

sub update_contributors_form {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $object->meta);
    $c->render(template => "update_contributors_form");
}


=head2 update_files

Update the files.

=cut

sub update_files {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    $c->stash(tab => "update_files_form");

    my $pub = $object->get_publication(autocreate => 1) or
        return $c->update_error( "Sorry, file uploads have only been implemented for publications.");

    my $file = $c->req->upload('file_upload');
    if ($file && $file->size) {
        $pub->upload_file(c => $c, upload => $file) or
            return $c->update_error($pub->error);
    }
    if (my $file_url = $c->param('file_url')) {
        $c->app->log->info("Getting $file_url for ".$object->meta->table."  ".(join '/',$object->pk_values));
        my $tx = $c->app->ua->get($file_url);
        my $res = $tx->success or
            return $c->update_error( "Error getting $file_url : ".$tx->error);
        my $content = $res->body;

        my $filename = Mojo::URL->new($file_url)->path->parts->[-1];
        my $up = Mojo::Upload->new;
        $up->filename($filename);
        $up->asset(Mojo::Asset::File->new->add_chunk($content));
        $pub->upload_file(c => $c, upload => $up) or
            return $c->update_error( $pub->error);
    }

    my $image_dir = $c->config('image_upload_dir') or do { logger->error("no image_upload_dir configured"); die "configuration error"; };
    if (my $id = $c->param('delete_file')) {
        my $obj = File->new(identifier => $id)->load(speculative => 1) or
        return $c->update_error("could not find file $id");
        $obj->meta->error_mode('return');
        my $filename = "$image_dir".'/'.$obj->file;
        my $entry = PublicationFileMap->new(
            publication => $pub->id,
            file => $obj->identifier
        );
        $entry->delete or return $c->update_error($obj->error);
        $obj = File->new(identifier => $obj->identifier)->load;
        my @others = $obj->publications;
        unless (@others) {
            $obj->delete or return $c->update_error($obj->error);
            -e $filename and do { unlink $filename or die $!; };
        }
        $c->flash(message => 'Saved changes');
        return $c->redirect_without_error('update_files_form');
    }
    if (my $existing = $c->param('add_existing_file')) {
        my $file = File->new_from_autocomplete($existing)
            or return $c->update_error("No match for $existing");
        my $entry = PublicationFileMap->new(publication => $pub->id, file => $file->identifier);
        $entry->save(audit_user => $c->user) or return $c->update_error($entry->error);
        $c->stash(message => 'Saved changes.');
        return $c->redirect_without_error('update_files_form');
    }

    return $c->redirect_without_error('update_files_form');
}

=head2 put_files

PUT files.

=cut

sub put_files {
    my $c = shift;
    my $file = Mojo::Upload->new(asset => Mojo::Asset::File->new->add_chunk($c->req->body));
    $file->filename($c->stash("filename") ||  'asset');
    my $obj = $c->_this_object;
    my $pub = $obj->get_publication(autocreate => 1);
    $pub->upload_file(c => $c, upload => $file) or do {
        return $c->render(status => 500, text => $pub->error);
    };
    $c->render(text => "ok");
}

=head2 update_contributors

Update the contributors associated with this publication.

=cut

sub update_contributors {
    my $c = shift;
    my $obj = $c->_this_object;
    $c->stash(tab => 'update_contributors_form');
    my $pub = $obj->get_publication(autocreate => 1);
    $pub->save(audit_user => $c->user) unless $pub->id;

    my $json = $c->req->json || {};

    if (my $id = $json->{delete_contributor} || $c->param('delete_contributor')) {
        PublicationContributorMaps->delete_objects({
                contributor_id => $id,
                publication_id => $pub->id,
            }) or return $c->update_error("Failed to remove contributor");
        $c->flash(info => "Saved changes.");
    }

    my ($person,$organization);

    my $reference_identifier;
    if ($c->req->json) {
        $person = $json->{person_id};
        $reference_identifier = $json->{reference_identifier};
        $organization = $json->{organization_identifier};
        logger->info("adding org $organization");
        if (my $id = $person) {
            $person = Person->new(id => $id)->load(speculative => 1)
                or return $c->update_error("invalid person $person");
        }
        if (my $id = $organization) {
            $organization = Organization->new(identifier => $id)->load(speculative => 1)
                or return $c->update_error("invalid organization $organization");
        }
    } else {
        $person = $c->param('person');
        $organization = $c->param('organization');
        $reference_identifier = $c->param('reference_identifier') || undef;
        $person &&= do { Person->new_from_autocomplete($person) or return $c->update_error("Failed to match $person"); };
        $organization &&= do { Organization->new_from_autocomplete($organization) or return $c->update_error("Failed to match $organization"); };
    }

    return $c->redirect_without_error('update_contributors_form') unless $person || $organization;

    my $role = $c->param('role') || $json->{role} or return $c->update_error("missing role");
    
    my $contributor = Contributor->new(role_type => $role);
    $contributor->organization_identifier($organization->identifier) if $organization;
    $contributor->person_id($person->id) if $person;
    if ( $contributor->load(speculative => 1)) {
            logger->debug("Found contributor person ".($person // 'undef').' org '.($organization) // 'undef');
            logger->debug("json : ".Dumper($json));
    } else {
            $contributor->save(audit_user => $c->user)
                or return $c->update_error($contributor->error);
    };

    $pub->save(audit_user => $c->user) or return $c->update_error($contributor->error);
    my $map = Tuba::DB::Object::PublicationContributorMap->new(
        publication_id => $pub->id,
        contributor_id => $contributor->id
    );
    $map->load(speculative => 1);
    $map->reference_identifier($reference_identifier);
    $map->save(audit_user => $c->user) or return $c->update_error($map->error);
    $c->flash(info => "Saved changes.");
    return $c->redirect_without_error('update_contributors_form');
}

=head2 update_keywords

Assign GCMD keywords to a resource.

=cut

sub update_keywords {
    my $c = shift;
    my $obj = $c->_this_object or return $c->render_not_found;
    my $pub = $obj->get_publication(autocreate => 1);
    $pub->save(audit_user => $c->user) unless $pub->id;
    if (my $json = $c->req->json) {
        my $delete_extra = delete $json->{_delete_extra};
        $json = [ $json ] if ref($json) eq 'HASH';
        my %to_delete = map { ($_->identifier => 1) } @{ $pub->gcmd_keywords };

        for my $k (@$json) {
            ref $k eq 'HASH' or return $c->render(json => { error => { data => $k, msg => "not a hash" }} );
            my $kw = exists $k->{identifier} ? GcmdKeyword->new(%$k) : GcmdKeyword->new_from_flat(%$k);
            $kw->load(speculative => 1) or return $c->render(json => { error => { data => $k, msg => 'not found' }} );
            $pub->add_gcmd_keywords($kw);
            delete $to_delete{$kw->identifier};
        }
        $pub->save(audit_user => $c->user);
        if ($delete_extra) {
            for my $extra (keys %to_delete) {
                PublicationGcmdKeywordMap->new(
                  publication        => $pub->id,
                  gcmd_keyword_identifier => $extra
                )->delete;
            }
        }
        return $c->render(json => 'ok');
    }
    return $c->render(text => "html not implemented"); # TODO
}

=head2 update_rel

Update the relationships.

=cut

sub update_rel {
    my $c = shift;
    my $object = $c->_this_object;
    my $next = $object->uri($c,{tab => 'update_rel_form'});

    my $pub = $object->get_publication(autocreate => 1);
    $pub->save(audit_user => $c->user) unless $pub->id;

    # Update generic relationships for all publication types.
    if (my $new = $c->param('new_gcmd_keyword')) {
        my $kwd = GcmdKeyword->new_from_autocomplete($new);
        $pub->add_gcmd_keywords($kwd);
        $pub->save(audit_user => $c->user) or do {
            $c->flash(error => $object->error);
            return $c->redirect_to($next);
        };
    }
    for my $id ($c->param('delete_gcmd_keyword')) {
        next unless $id;
        PublicationGcmdKeywordMaps->delete_objects(
            { gcmd_keyword_identifier => $id,
              publication_id => $pub->id });
        $c->flash(message => 'Saved changes');
    }

    $c->respond_to(
        json => sub {
            shift->render(json => { status => 'ok' })
        },
        html => sub {
            return shift->redirect_to($next);
        },
    );
}


=head2 update

Generic update for an object.

=cut

sub _differ {
    my ($x,$y) = @_;
    return 1 if !defined($x) && defined($y);
    return 1 if defined($x) && !defined($y);
    return 0 if !defined($x) && !defined($y);
    return 1 if $x ne $y;
    return 0;
}

sub normalize_form_parameter {
    my $c = shift;
    my %args = @_;
    my ($column, $value) = @args{qw/column value/};
    if ($column eq 'organization_identifier') {
        my $org = Organization->new_from_autocomplete($value);
        return $org->identifier if $org;
    }
    return $value;
}

sub update {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    my $next = $object->uri($c,{tab => 'update_form'});
    my %pk_changes;
    my %new_attrs;
    my $table = $object->meta->table;
    my $computed = $c->stash('computed_params') || {}; # to override incoming params in a subclass.
    $object->meta->error_mode('return');
    my $json = ($c->stash('object_json') || $c->req->json);

    if ($c->param('delete')) {
        if ($object->delete) {
            $c->flash(message => "Deleted $table");
            return $c->redirect_to('list_'.$table);
        }
        $c->flash(error => $object->error);
        return $c->redirect_to($next);
    }

    my $ok = 1;
    my $audit_note = $c->stash('audit_note') || (delete $json->{audit_note}) || $c->param('audit_note');
    for my $col ($object->meta->columns) {
        my $param = $json ? $json->{$col->name} : $c->req->param($col->name);
        $param = $computed->{$col->name} if exists($computed->{$col->name});
        $param = $c->stash('report_identifier') if $col->name eq 'report_identifier' && $c->stash('report_identifier');
        $param = $c->normalize_form_parameter(column => $col->name, value => $param);
        $param = undef unless defined($param) && length($param);
        my $acc = $col->accessor_method_name;
        $new_attrs{$col->name} = $object->$acc; # Set to old, then override with new.
        $new_attrs{$col->name} = $param if _differ($param,$new_attrs{$col->name});
        if ($col->is_primary_key_member && ($param//'' ne $object->$acc)) {
            die "$acc is not defined" unless defined($param);
            $pk_changes{$col->name} = $param;
            # $c->app->log->debug("Setting primary key member ".$col->name." to $param");
            next;
        }
        $c->app->log->debug("Setting $acc to ".($param // 'undef'));
        eval { $object->$acc($param); };
        if (my $err = $@) {
            $err =~ s[ at /.+/Controller.pm line \d+][];
            $err = "$acc : $err";
            $ok = 0;
            $object->error($err);
            last;
        }
    }

    if ($ok && keys %pk_changes) {
        $c->app->log->debug("Updating primary key");
        # See Tuba::DB::Object.
        if (my $new = $object->update_primary_key(audit_user => $c->user, audit_note => $audit_note, %pk_changes, %new_attrs)) {
            $new->$_($object->$_) for map { $_->is_primary_key_member ? () : $_->name } $object->meta->columns;
            $object = $new;
        } else {
            $ok = 0;
        }
    }

    if ($ok) {
        $ok = $object->save(changes_only => 1, audit_user => $c->user, audit_note => $audit_note);
        $ok &&= $c->post_update($object);
    }
    if ($c->detect_format eq 'json') {
        return $c->update_form if $ok;
        return $c->render(json => { error => $object->error });
    }
    $ok and do {
        $next = $object->uri($c,{tab => 'update_form'});
        $c->flash(message => "Saved changes"); return $c->redirect_to($next); };
    $c->flash(error => substr($object->error,0,1000));
    $c->redirect_to($next);
}

=head2 remove

Generic delete

=cut

sub remove {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    $object->meta->error_mode('return');
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
        $count = Publications->get_objects_count;
    }
    my $demo_pubs;
    push @$demo_pubs, @{ Publications->get_objects(
            offset => ( int rand $count ),
            limit => 1,
        ) } for (1..6);
    $c->stash(demo_pubs => [ shuffle @$demo_pubs ]);
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

    for my $row (reverse @$change_log) {
        my $row_data = $row->{changed_fields} || $row->{row_data};
        my $old = hstore_decode($row->{row_data} // '');
        my $changes = hstore_decode($row->{changed_fields} // '');
        my $new = { %$old, %$changes };
        $row->{diffs} = show_diffs(Dump($old),Dump($new));
    }
    $c->render(template => 'history', change_log => $change_log, object => $object, pk => $pk)
}

sub render {
    my $c = shift;
    my %args = @_;
    my $obj = $c->stash('object') || $args{object} or return $c->SUPER::render(@_);
    my $moniker = $obj->moniker;
    if (!defined($c->stash($moniker))) {
        $c->stash($moniker => $obj);
    }
    return $c->SUPER::render(@_);
}

sub page {
    my $c = shift;
    my $page = $c->param('page') || 1;
    $page = $c->_favorite_page if $page eq '♥';
    if (my $accept = $c->req->headers->content_range) {
        if ($accept =~ /^page=(\d+)$/i) {
            $page = $1;
        }
    }
    $page = 1 unless $page && $page =~ /^\d+$/;
    $c->stash(page => $page);
    return $page;
}

sub per_page {
    my $c = shift;
    return 24 if $c->param('thumbs');
    return 20;
}

sub set_pages {
    my $c = shift;
    my $count = shift || 1;
    $c->stash(pages => 1 + int(($count - 1)/$c->per_page));
    $c->stash(per_page => $c->per_page);
    $c->stash(count => $count);
}

sub update_error {
    my $c = shift;
    my $err = shift;
    return $c->redirect_with_error($c->stash('tab'),$err);
}

sub redirect_with_error {
    my $c     = shift;
    my $tab   = shift;
    my $error = nice_db_error(shift);
    my $uri   = $c->_this_object->uri($c, {tab => $tab});
    logger->debug("redirecting with error : $error");
    $c->respond_to(
        json => sub {
            shift->render(status => 400, json => { error => $error })
        },
        html => sub {
            my $c = shift;
            $c->flash(error => $error);
            return $c->redirect_to($uri);
        },
    );
}

sub redirect_without_error {
    my $c     = shift;
    my $tab   = shift;
    my $uri   = $c->_this_object->uri($c, {tab => $tab});
    $c->respond_to(
        html => sub { shift->redirect_to($uri) },
        json => sub { shift->render(json => { status => 'ok' }) }
    );
}


1;
