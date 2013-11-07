=head1 NAME

Tuba::Reference : Controller class for references.

=cut

package Tuba::Reference;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $pub = $c->current_report->get_publication(autocreate => 1);
    my $all = $c->param('all');
    my $refs = References->get_objects(
       query => [publication_id => $pub->id],
       with_objects => 'publication_maps',
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
            my ($type,$identifier) = $uri =~ m[/([^/]+)/([^/]+)$];
            die "unsupported type ($uri) : $type" unless $type eq 'report';
            my $pub = Report->new(identifier => $identifier)->get_publication(autocreate => 1);
            $pub->save(audit_user => $c->user) unless $pub->id;
            $json->{publication_id} = $pub->id;
            $c->stash(object_json => $json);
        }
    }
    # $c->stash(computed_params => { publication_id => $pub->id } );
    $c->SUPER::create(@_);
}

sub update {
    my $c = shift;
    if (my $json = $c->req->json) {
        if (my $uri = delete $json->{publication_uri}) {
            my ($type,$identifier) = split '/', $uri;
            die "unsupported type ($uri) : $type" unless $type eq 'report';
            my $pub = Report->new(identifier => $identifier)->get_publication(autocreate => 1);
            $json->{publication_id} = $pub->id;
            $c->stash(object_json => $json);
        }
    }
    # $c->stash(computed_params => { publication_id => $pub->id } );
    $c->SUPER::update(@_);
}

sub smartmatch {
    # Match this reference to a child publication.
    my $c = shift;
    my $reference = $c->_this_object;
    my @tables = map $_->table, @{ PublicationTypes->get_objects(all => 1) };
    my $match;
    for my $table (@tables) {
        my $obj_class = $c->orm->{$table}{obj} or die "no manager for $table";
        $match = $obj_class->new_from_reference($reference) and last;
    }
    die "not implemented" if $match;
    $c->respond_to(
      json => sub {
        shift->render(
          json => {publication_uri => ($match ? $match->uri($c) : undef),});
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
        # TODO
    }
    $c->redirect_without_error('update_rel_form');
}

1;

