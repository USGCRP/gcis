=head1 NAME

Tuba::Organization : Controller class for organizations.

=cut

package Tuba::Organization;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use Tuba::Log qw/logger/;

sub show {
    my $c = shift;
    my $meta = Organization->meta;
    my $identifier = $c->stash('organization_identifier');
    my $object = Organization->new( identifier => $identifier )->load( speculative => 1 )
      or return $c->render_not_found;
    $c->stash(object => $object);
    return $c->SUPER::show(@_);
}

sub update_rel {
    my $c = shift;
    my $org = $c->_this_object;
    my $next = $org->uri($c,{tab => 'update_rel_form'});
    $c->stash(tab => "update_rel_form");
    my $json = $c->req->json;

    if (my $pub_id = $json->{delete_publication} || $c->param('delete_publication')) {
        my $con_id = $json->{contributor_id} || $c->param('contributor_id');
        die "person does not match contributor" unless Contributor->new(id => $con_id)->load->organization_identifier == $org->identifier;
        PublicationContributorMaps->delete_objects({
                contributor_id => $con_id,
                publication_id => $pub_id,
            }) or return $c->update_error("Failed to remove publication");
    } elsif (my $id = $json->{delete_contributor} || $c->param('delete_contributor')) {
        die "person does not match contributor" unless Contributor->new(id => $id)->load->organization_identifier == $org->identifier;
        Contributors->delete_objects({ id => $id })
            or return $c->update_error("Failed to remove contributor");
        $c->flash(info => "Saved changes.");
    }

    if (my $obj = $c->param('publication')) {
        my $person = Person->new_from_autocomplete($c->param('person') // '');
        my $obj = $c->param('publication') or return $c->update_error("Missing publication");
        $obj = $c->str_to_obj($obj) or return $c->update_error("No match for $obj");
        my $pub = $obj->get_publication(autocreate => 1);
        $pub->save(audit_user => $c->user) unless $pub->id;
        my $role_type = $c->param('role_type');
        my $ctr = Contributor->new(
          role_type_identifier    => $role_type,
          person_id               => $person ? $person->id : undef,
          organization_identifier => $org->identifier
        );
        $ctr->load(speculative => 1) or $ctr->save(audit_user => $c->user) or return $c->update_error($ctr->error); 
        $ctr->add_publications($pub);
        $ctr->save(audit_user => $c->user) or return $c->update_error($ctr->error);
    }

    $c->redirect_to($next);
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

sub merge {
    my $c = shift;
    my $org = $c->_this_object;
    $c->stash(tab => "update_form");
    $c->stash->{template} = 'update_form';
    my $other
      = $c->req->json
      ? Organization->new(identifier => $c->req->json->{merge_organization})
      : $c->str_to_obj($c->param('merge_organization'));
    return $c->update_error("Missing other organization") unless $other;
    logger->info(sprintf("Merging organization %s (%s) with %s (%s)",
           $org->name, $org->identifier, $other->name, $other->identifier ));
    if ($org->identifier eq $other->identifier) {
        return $c->update_error("Cannot merge org with itself.");
    }

    my $dbs = $c->dbs;
    eval {
      $dbs->begin_work;
      $dbs->update('contributor',
        { organization_identifier => $other->identifier},
        { organization_identifier => $org->identifier })
        or die $dbs->errstr;
      $org->delete;
      $dbs->commit or die $dbs->error;
    };
    if ($@) { return $c->update_error($@) }

    $c->stash(info => "Merged with ".$other->identifier);
    my $uri = $other->uri($c, { tab => 'update_form' } );
    return $c->redirect_to($uri);
}


1;

