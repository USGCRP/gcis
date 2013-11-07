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

1;

