=head1 NAME

Tuba::Reference : Controller class for references.

=cut

package Tuba::Reference;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use Rose::DB::Object::Util qw/:all/;
use Tuba::Log qw/logger/;;

sub list {
    my $c = shift;
    my $pub = $c->current_report->get_publication(autocreate => 1);
    my $all = $c->param('all');
    my $refs = References->get_objects(
       query => [publication_id => $pub->id],
       ( $all ? () : (page => $c->page, per_page => $c->per_page) )
    );
    unless ($all) {
        my $count = References->get_objects_count(
          query => [publication_id => $pub->id],
        );
        $c->set_pages($count);
    }
    $c->stash(objects => $refs);
    $c->stash(title => "References for ".$c->current_report->identifier." report");
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('reference_identifier');
    my $reference = Reference->new(identifier => $identifier);
    $reference->load(speculative => 1) or return $c->render_not_found;
    $c->stash( object => $reference);
    $c->SUPER::show(@_);
}

sub create {
    my $c = shift;
    if (my $json = $c->req->json) {
        if (my $uri = delete $json->{publication_uri}) {
            my $report = $c->uri_to_obj($uri) or return $c->render(json => { error  => "uri $uri not found" } );
            $report->meta->table eq 'report' or return $c->render(json => { error => 'only reports for now' } );
            my $pub = $report->get_publication(autocreate => 1);
            $pub->save(audit_user => $c->user) unless $pub->id;
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
  $reference->save(audit_user => $c->user);
  return 1;
}

sub update {
    my $c = shift;
    if (my $json = $c->req->json) {
        if (my $uri = delete $json->{publication_uri}) {
            my $report = $c->uri_to_obj($uri) or return $c->render(code =>400, json => { error  => 'uri not found' } );
            $report->meta->table eq 'report' or return $c->render(code =>501, json => { error => 'only reports for now' } );
            my $pub = $report->get_publication(autocreate => 1);
            $pub->save(audit_user => $c->user) unless $pub->id;
            $json->{publication_id} = $pub->id;
            $c->stash(object_json => $json);
        } else {
            return $c->render(code => 400, json => { error => 'missing publication uri (e.g. /report/nca3)' } );
        }
    }
    $c->SUPER::update(@_);
}

sub smartmatch {
    # Match this reference to a child publication.
    my $c         = shift;
    my $reference = $c->_this_object;
    $c->app->log->debug("matching [".$reference->attr('reftype')."]");
    my @tables    = map $_->table, @{PublicationTypes->get_objects(all => 1)};

    my @try = map $_->{obj}, values %{ $c->orm };
    my $existing = $reference->child_publication;
    if ($existing) {
        $existing->load;
        $existing = $existing->to_object(autoclean => 1) or die "orphan : ".$reference->child_publication->as_yaml;
    }
    logger->debug("matching : ".$reference->identifier);
    unshift @try, $existing if $existing;
    my $match;
    for my $class (@try) {
        $match = $class->new_from_reference($reference) and last;
    }
    logger->debug("match : ".($match // '<none>'));
    undef $match if $match && !is_in_db($match) && $c->param('updates_only');
    my $status = 'no match';
    if ($match) {
        $match->save(audit_user => $c->user);
        if (is_in_db($match)) {
            $status = 'match';
        } else {
            $status = 'new';
        }
        my $pub = $match->get_publication(autocreate => 1);
        $pub->save(audit_user => $c->user) unless $pub->id;
        $reference->child_publication_id($pub->id);
        $reference->save(audit_user => $c->user)
            or $c->redirect_with_error(update_rel_form => $reference->error);
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
    my $reference = $c->_this_object;
    my $report = $reference->publication->to_object;
    undef $report unless $report->meta->table eq 'report';
    if (my $child = $c->param('child_publication_id')) {
        my $obj = $c->str_to_obj($child);
        my $child_publication = $obj->get_publication(autocreate => 1);
        $child_publication->save(audit_user => $c->user) unless $child_publication->id;
        $reference->child_publication_id($child_publication->id);
        $reference->save(audit_user => $c->user) or return $c->redirect_with_error(update_rel_form => $reference->error);
    }
    if ( $report && (my $chapter_identifier = $c->param('chapter'))) {
        my $chapter = Chapter->new(identifier => $chapter_identifier, report_identifier => $report->identifier);
        my $chapter_pub = $chapter->get_publication(autocreate => 1);
        $chapter_pub->save(audit_user => $c->user) unless $chapter_pub->id;
        $reference->add_subpubrefs({ publication_id => $chapter_pub->id });
        $reference->save(audit_user => $c->user) or
            return $c->redirect_with_error(update_rel_form => $reference->error);
    }
    if (my $other_pub = $c->param('other_pub')) {
        my $obj = $c->str_to_obj($other_pub)
            or return $c->redirect_without_error(update_rel_form => "not found : $other_pub");
        my $pub = $obj->get_publication(autocreate => 1);
        $pub->save(audit_user => $c->user) unless $pub->id;
        $reference->add_subpubrefs({ publication_id => $pub->id });
        $reference->save(audit_user => $c->user) or
            return $c->redirect_with_error(update_rel_form => $reference->error);
    }
    # TODO allow deletion
    $c->redirect_without_error('update_rel_form');
}

1;

