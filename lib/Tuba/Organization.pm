=head1 NAME

Tuba::Organization : Controller class for organizations.

=cut

package Tuba::Organization;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $meta = Organization->meta;
    my $identifier = $c->stash('organization_identifier');
    my $object = Organization->new( identifier => $identifier )->load( speculative => 1 )
      or return $c->render_not_found;
    $c->stash(object => $object);
    return $c->SUPER::show(@_);
}

sub update_rel_form {
    my $c = shift;
    $c->stash(relationships => [ map Organization->meta->relationship($_), qw/datasets/ ]);
    $c->stash(controls => {
            datasets => sub {
                my ($c,$obj) = @_;
                +{
                    template => 'datasets',
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
    if (my $new = $c->param('new_dataset')) {
        my $dat = Dataset->new_from_autocomplete($new);
        $object->add_datasets($dat);
        $object->save(audit_user => $c->user) or do {
            $c->flash(error => $object->error);
            return $c->redirect_to($next);
        };
    }

    for my $id ($c->param('delete_dataset')) {
        next unless $id;
        DatasetOrganizationMaps->delete_objects({ dataset_identifier => $id, organization_identifier => $object->identifier});
        $c->flash(message => 'Saved changes');
    }

    return $c->redirect_to($next);
}

sub _default_order {
    return ( qw/identifier name organization_type_identifier country url/ );
}

sub create_form {
    my $c = shift;
    $c->stash(
      controls => {
        organization_type_identifier => sub {
          my $c = shift;
          +{
            template => 'select',
            params   => { values => [sort map $_->identifier, @{ OrganizationTypes->get_objects(all => 1) }], }
           };
          },
      country_code => sub {
          my $c = shift;
          +{
            template => 'select',
            params   => {
                values => [sort { $a->[0] cmp $b->[0] }
                map [ $_->name, $_->code ], @{ Countrys->get_objects(all => 1) }],
                value => "US",
              }
           };
      },
    },
    );
    $c->SUPER::create_form(@_);
}

sub lookup_name {
    my $c = shift;
    my $name = $c->req->json->{name} or return $c->render_not_found;
    my $org = Organization->new(name => $name)->load(speculative => 1);
    if ($org) {
        my $uri = $org->uri($c);
        return $c->redirect_to($uri);
    }
    return $c->render_not_found;
}

1;

