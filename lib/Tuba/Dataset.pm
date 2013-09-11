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
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->SUPER::show(@_);
}

sub update_rel_form {
    my $c = shift;
    $c->stash(relationships => [ map Dataset->meta->relationship($_), qw/organizations/ ]);
    $c->stash(controls => {
            organizations => sub {
                my ($c,$obj) = @_;
                +{
                    template => 'organizations',
                    params => { }
                  }
              }
        });

    $c->SUPER::update_rel_form(@_);
}

sub update_rel {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    my $next = $object->uri($c,{tab => 'update_rel_form'});
    $object->meta->error_mode('return');
    if (my $new = $c->param('new_organization')) {
        my $org = Organization->new_from_autocomplete($new);
        $object->add_organizations($org);
        $object->save(audit_user => $c->user) or do {
            $c->flash(error => $object->error);
            return $c->redirect_to($next);
        };
    }

    for my $id ($c->param('delete_organization')) {
        next unless $id;
        DatasetOrganizationMaps->delete_objects({ organization_identifier => $id, dataset_identifier => $object->identifier});
        $c->flash(message => 'Saved changes');
    }

    return $c->redirect_to($next);
}

1;

