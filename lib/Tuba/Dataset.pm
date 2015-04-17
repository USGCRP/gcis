=head1 NAME

Tuba::Dataset : Controller class for datasets.

=cut

package Tuba::Dataset;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $meta = Dataset->meta;
    my $identifier = $c->stash('dataset_identifier');
    $identifier =~ s/^\s+//;
    $identifier =~ s/\s+$//;
    my $object =
      Dataset->new( identifier => $identifier )->load(speculative => 1)
      or return $c->render_not_found_or_redirect;
    $c->stash(object => $object);
    $c->SUPER::show(@_);
}

sub lookup_doi {
    my $c = shift;
    my $doi = $c->stash('doi');
    my $obj = Dataset->new(doi => $doi)->load(speculative => 1) or return $c->reply->not_found;
    return $c->redirect_to($obj->uri($c));
}

sub make_tree_for_show {
    my $c = shift;
    my $dataset = shift;
    my $tree = $c->SUPER::make_tree_for_show($dataset, @_ );
    $tree->{instrument_measurements} = [
        map $_->as_tree, $dataset->instrument_measurements
    ];
    return $tree;
}

sub update_rel {
    my $c = shift;
    my $dataset = $c->_this_object;
    if (my $json = $c->req->json) {
        if (my $add = $json->{add_instrument_measurement}) {
            $add->{dataset_identifier} = $dataset->identifier;
            my $obj = InstrumentMeasurement->new( %$add );
            $obj->load(speculative => 1);
            $obj->save(audit_user => $c->user) or return $c->update_error($obj->error);
        } else {
            warn "no json";
        }
    }
    # TODO : handle form submission too
    return $c->redirect_without_error("update_rel_form");
}

1;

