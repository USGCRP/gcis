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
use Tuba::Util qw/nice_db_error show_diffs human_duration/;
use File::Temp;
use YAML qw/Dump/;
use Encode qw/encode decode/;
use Mojo::Util qw/camelize decamelize/;
use LWP::UserAgent;
use HTTP::Request;
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
        my $val = $obj->$method;
        $t{$method} =
             ref($val) && ref($val) eq 'DateTime::Duration' ?
                human_duration($val) : $val;
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
    return ( uri => $uri, href => $href,
        $c->maybe_include_generic_pub_rels($obj), # keywords, regions
    );
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
    $c->set_title(table => $table);

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
             $c->render_maybe("$table/$template", meta => $meta, objects => $objects )
                 or
             $c->render($template, meta => $meta, objects => $objects );
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
    $c->res->headers->content_type('text/plain; charset=utf-8');
    my $stringified = _stringify($thing);
    $c->res->body(encode('UTF-8',Dump($stringified)));
    $c->res->code(200);
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
    my %params;
    $params{with_gcmd} = 1 if $c->param('with_gcmd');
    $params{with_regions} = 1 if $c->param('with_regions');
    $params{bonsai} = 1 if $c->param('brief');
    my $ret = $obj->as_tree(c => $c, %params);
    if (my $gcid = $ret->{uri}) {
        my $others = $c->orm->{'exterm'}{mng}->get_objects(
           query => [ gcid => "$gcid" ],
           sort_by => "lexicon_identifier, term"
        );
        $ret->{aliases} = [ map +{
                url => scalar $_->native_url,
                context => $_->context,
                term => $_->term,
                lexicon => $_->lexicon_identifier,
            }, @$others ] if $others && @$others;
    }
    $ret;
}

sub maybe_include_generic_pub_rels {
    my $c = shift;
    my $obj = shift;
    my $pub = $obj->get_publication or return ();
    my $tree = {};
    $tree->{gcmd_keywords} = [ map $_->as_tree(@_), $pub->gcmd_keywords ] if $c->param('with_gcmd');
    $tree->{regions} = [ map $_->as_tree(@_), $pub->regions] if $c->param('with_regions');
    return %$tree;
}

sub set_title {
    my $c = shift;
    my %args = @_;
    if (my $object = $args{object}) {
        $c->stash(title => sprintf('%s: %s',
            $object->meta->table,
            $object->stringify(short => 1),
            ));
        return;
    }
    if (my $table = $args{table}) {
        $c->stash(title => ($c->stash('plural') || $c->plural($table)));
        return;
    }
    $c->stash(title => $c->req->url->path);
    return;
}

sub show {
    my $c = shift;

    my $object = $c->stash('object') or return $c->reply->not_found;
    my $meta  = $c->stash('meta') || $object->meta;
    $c->stash(meta => $meta) unless $c->stash('meta');
    my $table = $meta->table;
    $c->stash(relationships => $c->_order_relationships(meta => $meta));
    $c->stash(cols => $c->_order_columns(meta => $object->meta));
    $c->set_title(object => $object);

    $c->respond_to(
        yaml => sub { my $c = shift;
          $c->render_maybe("$table/object") or $c->render_yaml($c->make_tree_for_show($object)); },
        json => sub { my $c = shift;
          $c->render_maybe("$table/object") or $c->render(json => $c->make_tree_for_show($object)); },
        ttl   => sub { my $c = shift;
            $c->res->headers->content_type("application/x-turtle");
            $c->render_maybe("$table/object") or $c->render("object") },
        thtml => sub { my $c = shift;
            $c->res->headers->content_type("text/html;charset=UTF-8");
            $c->stash->{format} = 'ttl';
            $c->stash('turtle' => $c->render_partial_ttl($table));
            $c->stash->{format} = 'thtml';
            $c->render_maybe("$table/object") || $c->render("object");
        },
        html  => sub { my $c = shift;
            $c->param('long') and $c->render_maybe("$table/long/object") and return;
            $c->render_maybe("$table/object") or $c->render("object") },
        nt    => sub { my $c = shift;
            $c->res->headers->content_type("text/plain");
            $c->render_partial_ttl_as($table,'ntriples'); },
        rdfxml=> sub { my $c = shift;
            $c->res->headers->content_type("application/rdf+xml");
            $c->render_partial_ttl_as($table,'rdfxml'); },
        dot   => sub { my $c = shift;
            $c->res->headers->content_type('text/vnd.graphviz');
            $c->render_partial_ttl_as($table,'dot'); },
        rdfjson => sub { my $c = shift;
            $c->res->headers->content_type('application/json');
            $c->render_partial_ttl_as($table,'json'); },
        jsontriples => sub { my $c = shift;
            $c->res->headers->content_type('application/json');
            $c->render_partial_ttl_as($table,'json-triples'); },
        txt => sub { my $c = shift;
              $c->req->headers->content_type('text/plain');
              $c->render(text => $object->as_text); },
        svg   => sub { my $c = shift;
            $c->set_title(object => $object);
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
    $c->render_not_found_or_redirect;
    return 0;
}

sub _pk_to_stashval {
    # Map a primary key column name to a value in the stash
    my $c = shift;
    my $meta = shift;
    my $name = shift;
    my $stash_name = $name;
    $stash_name = $meta->table.'_'.$name if $name eq 'identifier';
    $stash_name .= '_identifier' unless $stash_name =~ /identifier/;
    return $c->stash($stash_name);
}

=head2 render_not_found_or_redirect

Before rendering a 404, check the history, and possibly redirect.

Note that this only checks the 'identifier'; e.g. in the case where
multiple changes have been made (/report/oldreport/figure/oldgigure),
there will be two redirects.  The first one will go to /report/newreport/figure/oldfigure,
and the second one will go to /report/newreport/figure/newfigure.

Also adding 'no redirect' to the audit note will prevent redirects.

=cut

sub render_not_found_or_redirect {
    my $c = shift;
    my $object_class = $c->_guess_object_class;
    my $meta = $object_class->meta;
    my $sql;
    my @bind;
    my $table_name = $meta->table;
    my $identifier;
    my $identifier_column;
    for my $name ($meta->primary_key_column_names) { ; # e.g. identifier, report_identifier
        my $val = $c->_pk_to_stashval($meta,$name) or next;
        if ($name =~ /^id(entifier)?$/) {
            $identifier = $val;
            $identifier_column = $name;
        }
        push @bind, $val;
        $sql .= " and " if $sql;
        $sql .= " row_data->'$name' = \$".@bind;
    }
    return $c->reply->not_found unless $identifier;

    my $sth = $c->db->dbh->prepare(<<SQL, { pg_placeholder_dollaronly => 1 });
select changed_fields->'$identifier_column'
 from audit.logged_actions where table_name='$table_name' and changed_fields?'$identifier_column'
 and $sql
 and audit_note not like '%no redirect%'
 order by transaction_id limit 1
SQL
    my $got = $sth->execute(@bind);
    my $rows = $sth->fetchall_arrayref;
    return $c->reply->not_found unless $rows && @$rows;
    my $replacement = $rows->[0][0];
    my $url = $c->req->url;
    $url =~ s{/$table_name/$identifier(?=/|$|\.)}{/$table_name/$replacement} or return $c->reply->not_found;
    return $c->redirect_to($url);
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
  $c->render_maybe("$table/create_form") or $c->render("create_form");
}

sub _default_order {
  return qw/report_identifier chapter_identifier identifier number ordinal
    title description caption statement start_time end_time duration lat_min lat_max lon_min lon_max time_start time_end/;
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
    my %valid = ( audit_note => 1, map { $_ => 1 } @{ $object_class->meta->columns } );
    my @invalid = grep !$valid{$_}, keys %obj;
    my $error;
    if (@invalid) {
        $error = join "\n", map "$_ is not a valid field.", @invalid;
    } else {
        my $new = $object_class->new(%obj);
        $new->meta->error_mode('return');
        my $table = $object_class->meta->table;
        $new->save(audit_user => $c->user, audit_note => $audit_note)
              and $c->post_create($new)
              and do {
                  $c->app->log->info("Successfully created ".$new->meta->table." : ".$new->stringify);
                  return $c->_redirect_to_view($new);
              };
        $error = $new->error;
    } 
    $c->app->log->error("Error creating $object_class : $error");
    $c->respond_to(
        json => sub {
                my $c = shift;
                # 422 is a webdav extension : "Unprocessable entity"
                $c->res->code($error =~ /(already exists|violates unique constraint)/ ? 409 : 422);
                $c->render(json => { error => $error } );
            },
        html => sub {
                my $c = shift;
                $c->flash(error => nice_db_error($error));
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
        my $val = $c->_pk_to_stashval($meta,$name);
        return unless defined($val);
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
        publication_id => sub {
            { template => 'autocomplete', params => { object_type => 'all' } }
        },
        child_publication_id => sub {
            { template => 'autocomplete', params => { object_type => 'all' } }
        },

        organization_identifier => sub {
            { template => 'autocomplete', params => { object_type => 'organization' } }
        },
        chapter_identifier => sub { my $c = shift;
                            +{ template => 'select',
                               params => { values => $c->_chaplist($c->stash('report_identifier')) } } },
        report_identifier  => sub { +{ template => 'select', params => { values => shift->_rptlist() } } },
        report_type_identifier => sub {
          +{
            template => 'select',
            params   => {
              values =>
                ['', map $_->identifier, @{ReportTypes->get_objects(all => 1)}]
            }
          };
          },
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


sub verify_consistent_chapter {
    # Ensure that the chapter of an object matches the one in the URL.
    # Returns 1 on success, 0 on failure
    my $c = shift;
    my $object = shift;
    my $chapter = $object->chapter;
    my $chapter_identifier = $c->stash('chapter_identifier');
    return 1 if !$chapter && !$chapter_identifier;
    return 1 if $chapter && $chapter_identifier && $chapter->identifier eq $chapter_identifier;
    $c->app->log->info("Chapter identifier ".($chapter_identifier // 'undef')
        . " does not match chapter ".($chapter ? $chapter->identifier : 'undef'));
    return 0;
}

=head2 update_form

Generic update_form.

=cut

sub update_form {
    my $c = shift;
    my $controls = $c->stash('controls') || {};
    $c->stash(controls => { $c->_default_controls, %$controls } );
    my $object = $c->_this_object or return $c->reply->not_found;
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
            $c->render_maybe("$table/update_form")
                or $c->render("update_form");
        }
    );
}

=head2 update_prov_form

Generic update_prov_form.

=cut

sub update_prov_form {
    my $c = shift;
    my $object = $c->_this_object or return $c->reply->not_found;
    $c->stash(object => $object);
    $c->stash(meta => $object->meta);
    my $pub = $object->get_publication(autocreate => 1) or return $c->render(text => $object->meta->table.' is not a publication');
    $c->stash(publication => $pub);
    my $parents = [];
    if ($pub) {
        $parents = [ $pub->get_parents ];
    }
    $c->stash( parents => $parents );
    $c->render("update_prov_form");
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
    my $object = $c->_this_object or return $c->reply->not_found;
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
        my $parent_pub = $parent->get_publication or return $c->update_error("No publication entry for $uri.");
        my $rel = $del->{parent_rel} or return $c->update_error("missing parent_rel");
        my $map = PublicationMap->new(
          child        => $pub->id,
          parent       => $parent_pub->id,
          relationship => $rel
        );
        $map->load(speculative => 1) or return $c->update_error("relationship $rel $uri not found");
        $map->delete or return $c->update_error($map->error);
    }

    my ($parent_pub,$rel,$note,$activity_identifier);
    if ($json) {
        if (my $parent_uri  = $json->{parent_uri}) {
            my $parent      = $c->uri_to_obj($parent_uri) or return $c->update_error("Couldn't find $parent_uri");
            $parent_pub     = $parent->get_publication(autocreate => 1) or return $c->update_error("$parent_uri is not a publication");
            $parent_pub->save(audit_user => $c->user) unless $parent_pub->id;
            $rel  = $json->{parent_rel} or return $c->update_error("Missing parent_rel");
            $note = $json->{note};
            $activity_identifier = $json->{activity};
        }
    }  else {
        my $parent_str   = $c->param('parent') or return $c->render;
        my $parent       = $c->_text_to_object($parent_str) or return $c->render(error => 'cannot parse publication');
        $parent_pub      = $parent->get_publication(autocreate => 1);
        $parent_pub->save(changes_only => 1, audit_user => $c->user) or return $c->render(error => $pub->error);
        $rel  = $c->param('parent_rel')    or return $c->render(error => "Please select a relationship");
        $note = $c->param('note');
        $activity_identifier = $c->param('activity');
        $activity_identifier = undef unless defined($activity_identifier) && length($activity_identifier);
    }

    return $c->redirect_without_error('update_prov_form') unless $parent_pub;

    if ($activity_identifier) {
        unless ($json) {
            my $activity = $c->_text_to_object($activity_identifier)
                or return $c->update_error("Could not find activity identifier '$activity_identifier'.");
            $activity_identifier = $activity->identifier;
        }
        Activity->new(identifier => $activity_identifier)->load(speculative => 1)
            or return $c->update_error("Could not find activity identifier '$activity_identifier'.");
    }

    my $map = PublicationMap->new(
        child        => $pub->id,
        parent       => $parent_pub->id,
        relationship => $rel,
        note         => $note,
        activity_identifier => $activity_identifier,
    );
    $map->load(speculative => 1);
    $map->save(audit_user => $c->user) or return $c->update_error($map->error);
    $c->stash(info => "Saved $rel : ".$parent_pub->stringify);
    return $c->redirect_without_error('update_prov_form');
}

=head2 update_rel_form

Form for updating the relationships.

Override this and set 'relationships' to relationships that should
be on this page, e.g.

    $c->stash(relationships => [ map Figure->meta->relationship($_), qw/images/ ]);

=cut

sub update_rel_form {
    my $c = shift;
    my $object = $c->_this_object or return $c->reply->not_found;
    my $controls = $c->stash('controls') || {};
    $c->stash(controls => { $c->_default_rel_controls, %$controls } );
    my $meta = $object->meta;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    my $table = $meta->table;
    $c->render_maybe("$table/update_rel_form")
        or $c->render("update_rel_form");
}

=head2 update_files_form

Form for updating files.

=cut

sub update_files_form {
    my $c = shift;
    my $object = $c->_this_object or return $c->reply->not_found;
    $c->stash(object => $object);
    $c->stash(meta => $object->meta);
    $c->render("update_files_form");
}

=head2 update_contributors_form

Form for updating contributors.

=cut

sub update_contributors_form {
    my $c = shift;
    my $object = $c->_this_object or return $c->reply->not_found;
    $c->stash(object => $object);
    $c->stash(meta => $object->meta);
    $c->render("update_contributors_form");
}


=head2 update_files

Update the files.

=cut

sub update_files {
    my $c = shift;
    my $object = $c->_this_object or return $c->reply->not_found;
    $c->stash(tab => "update_files_form");

    my $pub = $object->get_publication(autocreate => 1) or
        return $c->update_error( "Sorry, file uploads have only been implemented for publications.");
   unless ($pub->id) {
      $pub->save(audit_user => $c->user)
        or return $c->update_error($pub->error);
   }

    my $file = $c->req->upload('file_upload');
    if ($file && $file->size) {
        $pub->upload_file(c => $c, upload => $file) or
            return $c->update_error($pub->error);
    }
    my $json = $c->req->json || {};
    if (my $file_url = ($json->{file_url} || $c->param('file_url'))) {
        $c->app->log->info("Getting $file_url for ".$object->meta->table."  ".(join '/',$object->pk_values));
        my $ua = $c->app->ua;
        $ua->max_redirects(3);

        my ($content, $content_type);
        if ($file_url =~ /^ftp/) {
            my $lwp = LWP::UserAgent->new();
            my $req = HTTP::Request->new(GET => $file_url);
            my $res = $lwp->request($req);
            $content = $res->content;
        } else {
            my $tx = $ua->get($file_url);
            my $res = $tx->success or
                return $c->update_error( "Error getting $file_url : ".$tx->error->{message});
            $c->app->log->info("Got $file_url, code is ".$res->code);
            $content_type = $res->headers->content_type;
            $content = $res->body;
        }

        my $remote_url = Mojo::URL->new($file_url);
        my $filename = $remote_url->path->parts->[-1];
        my $up = Mojo::Upload->new;
        $up->filename($filename);
        $up->asset(Mojo::Asset::File->new->add_chunk($content));
        my $new_file = $pub->upload_file(c => $c, upload => $up, type => $content_type)
            or return $c->update_error( $pub->error);
        if ($json->{use_remote_location} || $c->param('use_remote_location')) {
            # generate thumbnail first then remove it.
            $new_file->generate_thumbnail;
            $new_file->unlink_asset;
            my $new = Mojo::URL->new;
            $new->scheme($remote_url->scheme);
            $new->host($remote_url->host);
            $new->port($remote_url->port) if $remote_url->port;
            $new_file->location($new->to_string);
            $new_file->file($remote_url->path);
            $new_file->save(audit_user => $c->user);
            logger->info("saving remote asset ".$remote_url);
        }
        if (my $landing_page = ($json->{landing_page} || $c->param('landing_page')) ) {
            $new_file->landing_page($landing_page);
            $new_file->save(audit_user => $c->user);
        }
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

    my $existing_file;
    if (my $existing = $c->param('add_existing_file')) {
        $existing_file = File->new_from_autocomplete($existing)
            or return $c->update_error("No match for $existing");
    }
    if (my $existing = $json->{add_existing_file}) {
        $existing =~ s[^/file/][]; # accept URI or identifier
        $existing_file = File->new(identifier => $existing)
            ->load(speculative => 1) or return $c->update_error("No file : $existing");
    }
    if ($existing_file) {
        my $entry = PublicationFileMap->new(publication => $pub->id, file => $existing_file->identifier);
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
    my $obj = $c->_this_object or return $c->reply->not_found;
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
    if ($json && keys %$json) {
        # TODO JSON interface for updating sort keys
    } else {
        for my $con ($pub->contributors) {
            my $sort_key = $c->param('sort_key_'.$con->id);
            next unless defined($sort_key) && length($sort_key);
            next unless $sort_key =~ /^[0-9]+$/;
            my $map = PublicationContributorMap->new(publication_id => $pub->id, contributor_id => $con->id);
            $map->load(speculative => 1) or return $c->update_error("bad pub/contributor map ids");
            next if $map->sort_key && $map->sort_key == $sort_key;
            $map->sort_key($sort_key);
            $map->save(audit_user => $c->user) or return $c->update_error("could not save ".$map->error);
            $c->flash(info => "Saved changes");
        }
    }

    my ($person,$organization);

    my $reference_identifier;
    if ($c->req->json) {
        $person = $json->{person_id};
        $reference_identifier = $json->{reference_identifier};
        $organization = $json->{organization_identifier};
        logger->info("adding org $organization") if $organization;
        if (my $id = $person) {
            $person = Person->new(id => $id)->load(speculative => 1)
                or return $c->update_error("invalid person $person");
        }
        if (my $id = $organization) {
            $id =~ s[^/organization/][]; # Allow GCID or identifier
            $organization = Organization->new(identifier => $id)->load(speculative => 1)
                or return $c->update_error("invalid organization $id");
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

sub _update_pub_many {
    my $c = shift;
    my $what = shift;
    my $obj = $c->_this_object or return $c->reply->not_found;
    my $pub = $obj->get_publication(autocreate => 1);
    my $cwhat = "Tuba::DB::Object::$what";
    my $dwhat = decamelize($what);
    my $pwhat = $dwhat.'s';
    my $mwhat = "Tuba::DB::Object::Publication${what}Map";

    $pub->save(audit_user => $c->user) unless $pub->id;
    if (my $json = $c->req->json) {
        my $delete_extra = delete $json->{_delete_extra};
        $json = [ $json ] if ref($json) eq 'HASH';
        my %to_delete = map { ($_->identifier => 1) } @{ $pub->$pwhat };

        for my $k (@$json) {
            ref $k eq 'HASH' or return $c->render(json => { error => { data => $k, msg => "not a hash" }} );
            my $kw = exists $k->{identifier} ? $cwhat->new(%$k) : $cwhat->new_from_flat(%$k);
            $kw->load(speculative => 1) or return $c->render(json => { error => { data => $k, msg => 'not found' }} );
            my $method = "add_${dwhat}s";
            $pub->$method($kw);
            delete $to_delete{$kw->identifier};
        }
        $pub->save(audit_user => $c->user);
        if ($delete_extra) {
            for my $extra (keys %to_delete) {
                $mwhat->new(
                  publication        => $pub->id,
                  "${dwhat}_identifier" => $extra
                )->delete;
            }
        }
        return $c->render(json => 'ok');
    }
    return $c->render(text => "html not implemented"); # handled in update_rel.
}

=head2 update_keywords

Assign GCMD keywords to a resource.

=cut

sub update_keywords {
    return shift->_update_pub_many('GcmdKeyword');
}

=head2 update_regions

Assign regions to a resource.

=cut

sub update_regions {
    return shift->_update_pub_many('Region');
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

    # Update generic many-many relationships for all publication types.
    for my $what (qw/GcmdKeyword Region/) {
        my $cwhat = "Tuba::DB::Object::$what";
        my $dwhat = decamelize($what);
        my $mwhat = "Tuba::DB::Object::Publication${what}Map::Manager";

        if (my $new = $c->param("new_$dwhat")) {
            my $kwd = $cwhat->new_from_autocomplete($new);
            my $add_method = "add_${dwhat}s";
            $pub->$add_method($kwd);
            $pub->save(audit_user => $c->user) or do {
                $c->flash(error => $object->error);
                return $c->redirect_to($next);
            };
        }
        for my $id ($c->param("delete_$dwhat")) {
            next unless $id;
            $mwhat->delete_objects(
                { "${dwhat}_identifier" => $id,
                  publication_id => $pub->id });
            $c->flash(message => 'Saved changes');
        }
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
    return 1 if ref($x) || ref($y);
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

=head2 set_replacement

After deleting an object, indicate that another object takes precedence.

(Not implemented for composite primary keys.)

=cut

sub set_replacement {
    my $c = shift;
    my $table_name = shift;
    my $old_identifier = shift;
    my $new_identifier = shift;
    my $dbh = $c->dbs->dbh;
    $dbh->do(<<SQL, {}, "identifier=>$new_identifier", $old_identifier) and return 1;
        update audit.logged_actions set changed_fields = ?::hstore
         where action='D' and table_name='$table_name' and row_data->'identifier' = ?
SQL
    $c->stash(error => $dbh->errstr);
    return 0;
}

=head2 can_set_replacement

See above.

=cut

sub can_set_replacement {
    my $c = shift;
    my $meta = $c->_guess_object_class->meta;
    my @cols = $meta->primary_key_column_names;
    return 0 if @cols > 1;
    return 1;
}

sub update {
    my $c = shift;
    my $object = $c->_this_object or return $c->reply->not_found;
    my $next = $object->uri($c,{tab => 'update_form'});
    my %pk_changes;
    my %new_attrs;
    my $table = $object->meta->table;
    my $computed = $c->stash('computed_params') || {}; # to override incoming params in a subclass.
    $object->meta->error_mode('return');
    my $json = ($c->stash('object_json') || $c->req->json);

    my $error;
    if ($json) {
        my %valid = ( audit_note => 1, map { $_ => 1 } @{ $object->meta->columns } );
        my @invalid = grep !$valid{$_}, keys %$json;
        if (@invalid) {
            $error = join "\n", map "$_ is not a valid field.", @invalid;
        }
    }

    if ($c->param('delete')) {
        my $table_name = $object->meta->table;
        if ($object->delete) {
            my $identifier = $object->pk_values;
            my $new = $c->param('replacement_identifier');
            if ($identifier && $new) {
                $c->set_replacement($table_name, $identifier => $new);
            }
            $c->flash(message => "Deleted $table");
            return $c->redirect_to('list_'.$table);
        }
        $c->flash(error => $object->error);
        return $c->redirect_to($next);
    }

    my $ok = 1;
    $ok = 0 if $error;
    my $audit_note = $c->stash('audit_note');
    $audit_note ||= (delete $json->{audit_note}) if $json;
    $audit_note ||= $c->param('audit_note');
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
            $error = $err;
            last;
        }
    }

    if ($ok && keys %pk_changes) {
        $c->app->log->debug("Updating primary key");
        # See Tuba::DB::Object.
        if (my $new = $object->update_primary_key(audit_user => $c->user, audit_note => $audit_note, %pk_changes, %new_attrs)) {
            for my $col ($object->meta->columns) {
                if (!$col->is_primary_key_member) {
                    my $name = $col->name;
                    # handle case of updating an array
                    if ($col->type eq "array") {
                        $new->$name([$object->$name]);
                    } else {
                        $new->$name($object->$name);
                    }
                }
            }
            $object = $new;
        } else {
            $ok = 0;
        }
    }

    if ($ok) {
        $ok = $object->save(changes_only => 1, audit_user => $c->user, audit_note => $audit_note);
        $ok &&= $c->post_update($object);
    }
    if ($ok && ($c->detect_format eq 'json')) {
        return $c->update_form;
    }
    $error //= $object->error;
    if ($ok) {
        $next = $object->uri($c,{tab => 'update_form'});
        $c->flash(message => "Saved changes");
        return $c->redirect_to($next);
    }
    $c->respond_to(
      html => sub {
        my $c = shift;
        $c->flash(error => substr($error, 0, 1000));
        $c->redirect_to($next);
      },
      json => sub {
        my $c = shift;
        $c->res->code(
          $error =~ /(already exists|violates unique constraint)/ ? 409 : 422);
        $c->render(json => {error => $error});
      }
    );
}

=head2 remove

Generic delete

=cut

sub remove {
    my $c = shift;
    my $object = $c->_this_object or return $c->reply->not_found;
    $object->meta->error_mode('return');
    $object->delete or return $c->render_exception($object->error);
    return $c->render(text => 'ok');
}

=head2 index

Handles / for tuba.

=cut

sub index {
    my $c = shift;
    my %counts;
    for my $type (qw/person  dataset platform instrument model scenario report figure book journal article organization/) {
        $counts{$type} = $c->get_counts($type);
    }
    $c->stash(counts => \%counts);
    $c->respond_to(
        json => sub { shift->render(json => { counts => \%counts } ) },
        yaml => sub { shift->render_yaml( { counts => \%counts } ) },
        any  => sub { shift->render('index') },
    );
}

=item history

Generic history of changes to an object.

[ 'audit_username', 'audit_note', 'table_name', 'changed_fields', 'action_tstamp_tx', 'action' ],

=cut

sub history {
    my $c = shift;
    my $object = $c->_this_object or return $c->reply->not_found;
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
        ($row->{removed},$row->{added}) = show_diffs(Dump($old),Dump($new));
    }
    $c->render('history', change_log => $change_log, object => $object, pk => $pk)
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
    return undef if $c->param('all');
    return 24 if $c->param('thumbs');
    return 20;
}

sub set_pages {
    my $c = shift;
    my $count = shift // 1;
    if ($c->per_page) {
        $c->stash(pages => 1 + int(($count - 1)/$c->per_page));
        $c->stash(per_page => $c->per_page);
    } else {
        $c->stash(pages => 1);
    }
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
    my $uri;
    if (my $obj = $c->_this_object) {
        $uri = $c->_this_object->uri($c, {tab => $tab});
    } else {
        $uri = $c->_guess_object_class->uri($c, { tab => $tab } );
    }
    if (my $params = $c->stash('redirect_params')) {
        $uri = Mojo::URL->new($uri) unless ref($uri);
        $uri->query(@$params);
    }
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
    if (my $params = $c->stash('redirect_params')) {
        $uri = Mojo::URL->new($uri) unless ref($uri);
        $uri->query(@$params);
    }

    $c->respond_to(
        html => sub { shift->redirect_to($uri) },
        json => sub { shift->render(json => { status => 'ok' }) },
    );
}


1;
