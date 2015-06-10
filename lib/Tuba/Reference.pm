=head1 NAME

Tuba::Reference : Controller class for references.

=cut

package Tuba::Reference;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use Rose::DB::Object::Util qw/:all/;
use Tuba::Log qw/logger/;;
use Tuba::Util qw[new_uuid];

sub list {
    my $c = shift;
    my $pub;
    my $all = $c->param('all');
    my $obj = $c->current_report;
    return $c->redirect_to(
      $c->url_for(
        'list_report_references',
        {
          report_identifier => $obj->identifier,
          format            => $c->stash('format') || ""
        }
      )->query($c->req->url->query)
    );
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('reference_identifier');
    my $reference = Reference->new(identifier => $identifier);
    $reference->load(speculative => 1) or return $c->render_not_found_or_redirect;
    $c->stash( object => $reference);
    $c->SUPER::show(@_);
}

sub normalize_form_parameter {
    my $c = shift;
    my %args = @_;
    my ($column, $value) = @args{qw/column value/};
    my $obj;
    for ($column) {
        /^publication_id$/ and $obj = $c->str_to_obj($value);
        /^child_publication_id$/ and $obj = $c->str_to_obj($value);
    }
    if ($obj) {
        my $pub = $obj->get_publication(autocreate => 1);
        $pub->save(audit_user => $c->audit_user, audit_note => $c->audit_note) unless $pub->id;
        return $pub->id;
    }
    return $value;
}

sub create {
    my $c = shift;
    if (my $json = $c->req->json) {
        if (my $uri = delete $json->{publication_uri}) {
            my $report = $c->uri_to_obj($uri) or return $c->render(json => { error  => "uri $uri not found" } );
            $report->meta->table eq 'report' or return $c->render(json => { error => 'only reports for now' } );
            my $pub = $report->get_publication(autocreate => 1);
            $pub->save(audit_user => $c->audit_user, audit_note => $c->audit_note) unless $pub->id;
            $json->{publication_id} = $pub->id;
            $c->stash(object_json => $json);
        }
        $c->stash(sub_publication_uris => delete $json->{sub_publication_uris});
    }
    $c->SUPER::create(@_);
}

sub post_create {
  my $c         = shift;
  my $reference = shift;
  my $uris      = $c->stash('sub_publication_uris') or return 1;
  for my $uri (@$uris) {
    my $pub = $c->uri_to_pub($uri)
      or do { $reference->error("$uri not found"); return 0; };
    $reference->add_subpubrefs({publication_id => $pub->id});
  }
  $reference->save(audit_user => $c->user, audit_note => $c->stash('audit_note'));
  return 1;
}

sub update {
    my $c = shift;
    if (my $json = $c->req->json) {
        my $audit_note = delete($json->{audit_note});
        $c->stash(audit_note => $audit_note);

        # Turn uris into ids
        if (my $uri = delete $json->{publication_uri}) {
            my $obj = $c->uri_to_obj($uri) or return $c->render(status => 400, json => { error  => "uri $uri not found" } );
            my $pub = $obj->get_publication(autocreate => 1) or return $c->render(status => 400, json => { error => 'not a publication'});
            $pub->save(audit_user => $c->user, audit_note => $audit_note) unless $pub->id;
            $json->{publication_id} = $pub->id;
        } else {
            my $obj = $c->_this_object or return $c->render(status => 400, json => { error => "no object found" } );
            $json->{publication_id} = $obj->publication_id;
        }

        # ditto
        if (my $uri = delete $json->{child_publication_uri}) {
            my $obj = $c->uri_to_obj($uri) or return $c->render(status => 400, json => { error  => "uri $uri not found" } );
            my $pub = $obj->get_publication(autocreate => 1) or return $c->render(status => 400, json => { error => 'not a publication'});
            $pub->save(audit_user => $c->user, audit_note => $audit_note) unless $pub->id;
            $json->{child_publication_id} = $pub->id;
        } else {
            my $obj = $c->_this_object;
            $json->{child_publication_id} = $obj->child_publication_id;
        }

        $c->stash(object_json => $json);
        $c->stash(sub_publication_uris => delete $json->{sub_publication_uris});
        $c->stash(subpub_update_category => delete $json->{subpub_update_category});
    }
    $c->SUPER::update(@_);
}
sub post_update {
  my $c         = shift;
  my $reference = shift;
  my $uris      = $c->stash('sub_publication_uris') or return 1;
  my %existing  = map { $_->publication_id => 1 } $reference->subpubrefs;
  for my $uri (@$uris) {
    my $pub = $c->uri_to_pub($uri)
      or do { $reference->error("$uri not found"); return 0; };
    next if delete($existing{$pub->id});
    $reference->add_subpubrefs({publication_id => $pub->id});
  }
  $reference->save(audit_user => $c->user, audit_note => $c->stash('audit_note'));
  for my $pub_id (keys %existing) {
      my $s = Subpubref->new(reference_identifier => $reference->identifier, publication_id => $pub_id);
      if (my $cat = $c->stash('subpub_update_category')) {
          next unless $s->publication->publication_type_identifier eq $cat;
      }
      $s->load(speculative => 1) or next;
      $s->delete or do { $reference->error($s->error); return 0; };
  }
  return 1;
}


sub smartmatch {
    my $c         = shift;
    my $reference = $c->_this_object;
    $c->app->log->debug("matching [".$reference->attr('reftype')."]");
    my $audit_note;
    if (my $json = $c->req->json) {
        $audit_note = $json->{audit_note};
    }
    my @tables    = map $_->table, @{PublicationTypes->get_objects(all => 1)};

    # Match this reference to a child publication.
    my @try = map $_->{obj}, values %{ $c->orm };
    my $existing = $reference->child_publication;
    if ($existing) {
        $existing->load;
        $existing = $existing->to_object(autoclean => 1) or logger->warn("removed pub orphan : ".$reference->child_publication->as_yaml);
    }
    logger->debug("matching : ".$reference->identifier);
    unshift @try, $existing if $existing;
    my $match;
    for my $class (@try) {
        $match = $class->new_from_reference($reference, audit_user => $c->user, audit_note => $audit_note) and last;
    }
    logger->debug("match : ".($match // '<none>'));
    undef $match if $match && !is_in_db($match) && $c->param('updates_only');
    my $status = 'no match';
    if ($match) {
        logger->debug("saving");
        $match->save(audit_user => $c->user, audit_note => $audit_note) or return $c->redirect_with_error($match->error);
        if (is_in_db($match)) {
            $status = 'match';
        } else {
            $status = 'new';
        }
        my $pub = $match->get_publication(autocreate => 1);
        $pub->save(audit_user => $c->user, audit_note => $audit_note) unless $pub->id;
        $reference->child_publication_id($pub->id);
        $reference->save(audit_user => $c->user, audit_note => $audit_note)
            or return $c->redirect_with_error(update_rel_form => $reference->error);
    }

    $c->respond_to(
      json => sub {
        shift->render(
          json => {
              publication_uri => ( $match ? $match->uri($c) : undef),
              status          => $status,
          });
      },
      html => sub {
        shift->redirect_to('update_rel_form');
      }
    );
}

sub update_rel_form {
    my $c = shift;
    my $reference = $c->_this_object;
    my $report = $reference->publication->to_object;
    undef $report unless $report->meta->table eq 'report';
    my @chapters;
    if ($report) { 
        @chapters = ( [ 'add a chapter', ''], map [ $_->stringify, $_->identifier ], sort { $a->sortkey cmp $b->sortkey } $report->chapters );
    }
    $c->stash(chapters => \@chapters);
    $c->SUPER::update_rel_form(@_);
}

sub update_rel {
    my $c = shift;
    my $reference = $c->_this_object or return $c->reply->not_found;
    my $report = $reference->publication->to_object;
    undef $report unless $report->meta->table eq 'report';

    if (my $json = $c->req->json) {
        logger->info("got json");
        if (my $subpubref = $json->{add_subpubref_uri}) {
            logger->info("got $subpubref");
            # Add the URI for a chapter, figure, finding -- "sub publications" of a report --
            # to this references.
            my $pub = $c->uri_to_pub($subpubref) or do {
                return $c->render(status => 400, json => { error => "$subpubref not found" });
            };
            $reference->add_subpubrefs({publication_id => $pub->id});
            $reference->save(changes_only => 1, audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->render_exception;
        }
        if (my $subpubref = $json->{delete_subpub}) {
            my $pub = $c->uri_to_pub($subpubref) or do {
                return $c->render(status => 400, json => { error => "$subpubref not found" });
            };
            my $sub = Subpubref->new(reference_identifier => $reference->identifier, publication_id => $pub->id);
            $sub->load(speculative => 1) or return $c->redirect_with_error(update_rel_form => "$subpubref not found");
            $sub->delete or return $c->render_exception;
        }

        return $c->render(json => { status => 'ok'});
    }

    if ($c->param('delete_child_publication_id')) {
        $reference->child_publication_id(undef);
        $reference->save(changes_only => 1, audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->redirect_with_error(update_rel_form => $reference->error);
    }
    if (my $child = $c->param('child_publication_id')) {
        my $obj = $c->str_to_obj($child) or return $c->redirect_with_error(update_rel_form => "could not find $child");
        my $child_publication = $obj->get_publication(autocreate => 1);
        $child_publication->save(audit_user => $c->audit_user, audit_note => $c->audit_note) unless $child_publication->id;
        $reference->child_publication_id($child_publication->id);
        $reference->save(changes_only => 1, audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->redirect_with_error(update_rel_form => $reference->error);
    }
    if ( $report && (my $chapter_identifier = $c->param('chapter'))) {
        my $chapter = Chapter->new(identifier => $chapter_identifier, report_identifier => $report->identifier);
        my $chapter_pub = $chapter->get_publication(autocreate => 1);
        $chapter_pub->save(audit_user => $c->audit_user, audit_note => $c->audit_note) unless $chapter_pub->id;
        $reference->add_subpubrefs({ publication_id => $chapter_pub->id });
        $reference->save(changes_only => 1, audit_user => $c->audit_user, audit_note => $c->audit_note) or
            return $c->redirect_with_error(update_rel_form => $reference->error);
    }
    if (my $other_pub = $c->param('other_pub')) {
        my $obj = $c->str_to_obj($other_pub)
            or return $c->redirect_without_error(update_rel_form => "not found : $other_pub");
        my $pub = $obj->get_publication(autocreate => 1);
        $pub->save(audit_user => $c->audit_user, audit_note => $c->audit_note) unless $pub->id;
        $reference->add_subpubrefs({ publication_id => $pub->id });
        $reference->save(changes_only => 1, audit_user => $c->audit_user, audit_note => $c->audit_note) or
            return $c->redirect_with_error(update_rel_form => $reference->error);
    }
    if (my $which = $c->param('delete_subpub')) {
        my $sub = Subpubref->new(reference_identifier => $reference->identifier, publication_id => $which);
        $sub->load(speculative => 1) or return $c->redirect_with_error(update_rel_form => "$sub not found");
        $sub->delete or return $c->redirect_with_error(update_rel_form => $sub->error);
        $c->stash(message => "saved changes");
    }
    $c->redirect_without_error('update_rel_form');
}

# Look up a reference by record number.
sub lookup {
    my $c = shift;
    my $record_number = $c->stash('record_number');

    $record_number =~ /^[0-9]+$/ or return $c->reply->not_found;

    my $found = References->get_objects(query => [ \"attrs->'_record_number' = ${record_number}::varchar" ], limit => 10 );

    unless ($found && @$found) {
        return $c->reply->not_found;
    }
    if (@$found > 1) {
        return $c->respond_to(
            html => { text => "multiple matches : ".join ',', map $_->identifier, @$found },
            json => { json => { error => 'multiple matches : ', matches => [ map $_->identifier, @$found ] } },
            yaml => { json => { error => 'multiple matches : ', matches => [ map $_->identifier, @$found ] } }
        );
    }
    my $ref = $found->[0];
    $c->respond_to(
        html => sub { my $d = shift; $d->redirect_to($ref->uri($d)) },
        json => sub { my $d = shift; $d->redirect_to($ref->uri($d).".json") },
        yaml => sub { my $d = shift; $d->redirect_to($ref->uri($d).".yaml") },
    )
}

sub updates_report {
    my $c = shift;
    my $rows = $c->dbs->query(<<SQL)->hashes;
select
attrs->'_uuid' as reference, attrs->'DOI' as endnote_doi, a.doi as gcis_doi
from reference r
    inner join publication p on r.child_publication_id = p.id
    inner join article a on a.identifier = p.fk->'identifier'
where ( (a.doi != (attrs->'DOI')) or (a.doi is not null and (attrs->'DOI')::varchar is null))
SQL
    $c->stash(rows => $rows);
    return $c->render(template => "reference/report/updates");
}

sub set_title {
    my $c = shift;
    my %args = @_;
    my $obj = $args{object} || $c->stash('selected_object');
    if ($obj) {
        $c->stash(title => sprintf("References in %s",$obj->stringify(long => 1)));
        return;
    }
    return $c->SUPER::set_title(%args);
}


sub create_form {
    my $c = shift;
    $c->param(identifier => new_uuid());
    return $c->SUPER::create_form(@_);
}

sub list_for_publication {
    my $c = shift;
    my $obj = $c->stash('selected_object') || return $c->reply->not_found;
    my $pub = $obj->get_publication(autocreate => 1);
    my $all = !!$c->param('all');
    $c->stash(title => "References for ".$obj->stringify(short => 1));
    my $refs = References->get_objects(
               query => [publication_id => $pub->id],
               require_objects => ['subpubrefs'],
               ( $all ? () : (page => $c->page, per_page => $c->per_page))
    );
    $c->set_pages(References->get_objects_count( 
            query => [ "t2.publication_id" => $pub->id ],
            require_objects => ['subpubrefs'])) unless $all;
    $c->stash(objects => $refs);
    $c->SUPER::list(@_);
}

#sub show_for_publication {
#    my $c = shift;
#
#}

1;

