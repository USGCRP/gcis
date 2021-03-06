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
    my $object = Organization->new( identifier => $identifier )->load( speculative => 1, with_objects => [qw/organization_alternate_name/] )
      or return $c->render_not_found_or_redirect;
    $c->stash(object => $object);
    return $c->SUPER::show(@_);
}

sub list {
    my $c = shift;
    my @q;
    my $role;
    if (my $r = $c->param('role')) {
        @q = (query => [role_type_identifier => $r, person_id => undef], with_objects => [qw/contributors/]);
        $role = RoleType->new(identifier => $r)->load(speculative => 1);
    }
    $c->stash(role => $role);
    if ($c->param('all')) {
        $c->stash(objects => Organizations->get_objects(@q));
    } else {
        $c->stash(objects => scalar Organizations->get_objects(@q, sort_by => 'name', page => $c->page, per_page => $c->per_page));
        $c->set_pages(Organizations->get_objects_count(@q));
    }
    $c->SUPER::list(@_);
}

sub update_rel {
    my $c = shift;
    my $org = $c->_this_object;
    my $next = $org->uri($c,{tab => 'update_rel_form'});
    $c->stash(tab => "update_rel_form");
    my $json = $c->req->json;

    if (my $pub_id = $json->{delete_publication} || $c->param('delete_publication')) {
        my $con_id = $json->{contributor_id} || $c->param('contributor_id');
        die "person does not match contributor" unless Contributor->new(id => $con_id)->load->organization_identifier eq $org->identifier;
        PublicationContributorMaps->delete_objects(
            where => [{ contributor_id => $con_id, publication_id => $pub_id }],
            audit_user => $c->audit_user, audit_note => $c->audit_note)
        or return $c->update_error("Failed to remove publication");
    } elsif (my $id = $json->{delete_contributor} || $c->param('delete_contributor')) {
        die "person does not match contributor" unless Contributor->new(id => $id)->load->organization_identifier eq $org->identifier;
        Contributors->delete_objects(
            where => [{ id => $id }],
            audit_user => $c->audit_user, audit_note => $c->audit_note)
        or return $c->update_error("Failed to remove contributor");
        $c->flash(info => "Saved changes.");
    }

    if (my $obj = $c->param('publication')) {
        my $person = Person->new_from_autocomplete($c->param('person') // '');
        my $obj = $c->param('publication') or return $c->update_error("Missing publication");
        $obj = $c->str_to_obj($obj) or return $c->update_error("No match for $obj");
        my $pub = $obj->get_publication(autocreate => 1);
        $pub->save(audit_user => $c->audit_user, audit_note => $c->audit_note) unless $pub->id;
        my $role_type = $c->param('role_type');
        my $ctr = Contributor->new(
          role_type_identifier    => $role_type,
          person_id               => $person ? $person->id : undef,
          organization_identifier => $org->identifier
        );
        $ctr->load(speculative => 1) or $ctr->save(audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->update_error($ctr->error); 
        $ctr->add_publications($pub);
        $ctr->save(audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->update_error($ctr->error);
    }

    my $related;
    my $relationship;
    if (my $related_org = $c->param('related_org')) {
        $related = $c->str_to_obj($related_org) or return $c->update_error("Could not find $related_org");
        $relationship = $c->param('organization_relationship_identifier') or return $c->update_error("missing relationship");
    }
    if (my $related_org = $json->{'related_org'}) {
        $related = $c->uri_to_obj($related_org) or return $c->update_error("Could not find $related_org");
        $relationship = $json->{'relationship'} or return $c->update_error("missing relationship");
    }

    if ($related) {
        my $map = OrganizationMap->new(
          organization_identifier              => $org->identifier,
          other_organization_identifier        => $related->identifier,
          organization_relationship_identifier => $relationship
        );
        $map->save(audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->update_error($map->error);
        $c->flash(info => "Saved changes.");
    }
    if (my $delete_rel = $c->param('delete_relationship_to')) {
        my $type = $c->param('delete_relationship_type');
        my $related = Organization->new(identifier => $delete_rel);
        $related->load(speculative => 1) or return $c->update_error("related org not found");
        my $map = OrganizationMap->new(
                organization_identifier => $org->identifier,
                other_organization_identifier => $related->identifier,
                organization_relationship_identifier => $type
            );
        $map->load(speculative => 1) or return $c->update_error("relationship not found");
        $map->delete(audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->update_error($map->error);
        $c->stash(info => "Saved changes.");
    }

    if ( my $delete_alt_name = $c->param('delete_alternate_name') ) {
        my $alt_name = OrganizationAlternateName->new(
                organization_identifier => $org->identifier,
                identifier => $delete_alt_name
            )->load(speculative => 1) or return $c->update_error("alternate name not found");
        $alt_name->delete(audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->update_error($alt_name->error);
        $c->stash(info => "Alternate Name Removed.");
    }

    $c->redirect_to($next);
}

sub _default_order {
    return ( qw/identifier name organization_type_identifier country url/ );
}

sub _add_controls {
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
                values => [ "", 
                           sort { $a->[0] cmp $b->[0] }
                           map [ $_->name, $_->code ], @{ Countrys->get_objects(all => 1) }
                          ],
                value => "US",
              }
           };
      },
    },
   );
}

sub create_form {
    my $c = shift;
    $c->_add_controls;
    $c->SUPER::create_form(@_);
}

sub update_form {
    my $c = shift;
    $c->_add_controls;
    $c->SUPER::update_form(@_);
}

sub lookup_name {
    my $c = shift;
    my $name = $c->req->json->{name} or return $c->reply->not_found;
    my $org = Organization->new(name => $name)->load(speculative => 1);
    if ($org) {
        my $uri = $org->uri($c);
        return $c->redirect_to($uri);
    }
    return $c->reply->not_found;
}

sub contributions {
    my $c = shift;
    my $organization = $c->_this_object;
    my $role_identifier = $c->stash('role_type_identifier');
    my $resource = $c->stash('resource');
    my $maps = $c->orm->{publication_contributor_map}->{mng}->get_objects(
        query => [
                organization_identifier => $organization->identifier,
                role_type_identifier => $role_identifier,
                person_id => undef,
                publication_type_identifier => $resource,
        ],
        with_objects => [qw/contributor publication/],
    );
    my @pubs = map $_->publication, @$maps;
    my %id;
    @pubs = grep { !$id{$_->id}++} @pubs; 
    my @objs = map $_->to_object, @pubs;
    @objs = map $_->[1],
            sort { $a->[0] cmp $b->[0] }
            map [ $_->stringify(short => 1), $_ ], @objs;
    $c->stash(objs => \@objs);

    my $roletype = RoleType->new(identifier => $role_identifier)->load(speculative => 1) or return $c->reply->not_found;
    $c->stash(role => $roletype );
    $c->respond_to(
        json => { json => [ map $_->as_tree(c => $c, bonsai => 1), @objs ] },
        yaml => sub { shift->render_yaml([ map $_->as_tree(c => $c, bonsai => 1), @objs ]) },
        csv => sub { shift->render_csv([ map $_->as_tree(c => $c, bonsai => 1), @objs ]) },
        any => sub {
            shift->render,
        }
    );
}

sub make_tree_for_show {
    my $c = shift;
    my $org = shift;
    my $obj = $c->SUPER::make_tree_for_show($org);
    my $parents = OrganizationMaps->get_objects( query => [ organization_identifier => $org->identifier ] );
    $obj->{parents} = [ map +{ relationship => $_->organization_relationship_identifier,
                             organization => $_->other_organization->uri($c) }, @$parents ];
    my $children = OrganizationMaps->get_objects( query => [ other_organization_identifier => $org->identifier ] );
    $obj->{children} = [ map +{ relationship => $_->organization_relationship_identifier,
                              organization => $_->organization->uri($c) }, @$children ];

    return $obj;
}

# deprecated merge method
sub merge {
    my $c = shift;
    my $org = $c->_this_object;
    $c->stash(tab => "update_form");
    $c->stash->{template} = 'update_form';

    return $c->update_error("Missing other organization") unless $c->param('merge_organization');

    $c->param(delete => 1);
    $c->param(replacement_identifier => $c->param('merge_organization'));
    $c->update();
}

1;


