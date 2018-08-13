=head1 NAME

Tuba::Person : Controller class for people.

=cut

package Tuba::Person;
use Mojo::Base qw/Tuba::Controller/;
use Algorithm::Permute;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my @q;
    my $role;
    if (my $r = $c->param('role')) {
        @q = (query => [role_type_identifier => $r], with_objects => [qw/contributors/]);
        $role = RoleType->new(identifier => $r)->load(speculative => 1);
    }
    $c->stash(role => $role);
    if ($c->param('all')) {
        $c->stash(objects => Persons->get_objects(@q));
    } else {
        $c->stash(objects => scalar Persons->get_objects(@q, sort_by => 'last_name, first_name', page => $c->page, per_page => $c->per_page));
        $c->set_pages(Persons->get_objects_count(@q));
    }
    $c->SUPER::list(@_);
}

sub create {
    my $c = shift;

    if ( $c->param('orcid') ) {
        $c->stash(computed_params => { orcid => uc $c->param('orcid') });
    }
    elsif ( $c->req->json && $c->req->json->{'orcid'} ) {
        $c->req->json->{'orcid'} = uc $c->req->json->{'orcid'};
    }

    $c->SUPER::create(@_);
}



sub show {
    my $c = shift;
    my $identifier = $c->stash('person_identifier');
    my $person =
      Person->new( id => $identifier )
      ->load( speculative => 1, with => [qw/contributors/] )
      or return $c->render_not_found_or_redirect;

    $c->stash(object => $person);
    $c->stash(meta => Person->meta);
    return $c->SUPER::show(@_);
}

sub redirect_by_name {
    my $c = shift;
    my $name = $c->stash('name');
    my @pieces = split /[-_]/, $name;
    return $c->reply->not_found unless @pieces==2;
    my $front = Persons->get_objects(
      query => [
        [ \("lower(first_name) = ?") => (lc $pieces[0])],
        [ \("lower(last_name) = ?") => (lc $pieces[1]) ],
        ],
      limit => 10
    );
    my $back = Persons->get_objects(
      query => [
          [ \("lower(last_name) = ?")  => (lc $pieces[0]) ],
          [ \("lower(first_name) = ?") => (lc $pieces[1]) ],
      ],
      limit => 10
    );
    my @found = (@$front, @$back);

    return $c->reply->not_found unless @found;
    if (@found==1) {
        return $c->redirect_to('show_person', { person_identifier => $found[0]->id } );
    }

    $c->respond_to(
        json => sub {
            shift->render(json =>{ people =>  [ map $_->as_tree, @found ] }),
        },
        html => sub {
            return $c->render(people => \@found);
        },
    );
}

sub redirect_by_orcid {
    my $c = shift;
    my $orcid = uc $c->stash('orcid');
    my $person = Person->new(orcid => $orcid)->load(speculative => 1) or return $c->reply->not_found;
    return $c->redirect_to('show_person', { person_identifier => $person->id } );
}

sub _this_object {
    my $c = shift;
    my $obj = Person->new(id => $c->stash('person_identifier'));
    $obj->load(speculative => 1);
    return $obj;
}

sub _order_columns {
    my $c = shift;
    return [ qw/id first_name middle_name last_name orcid url/ ] unless $c->current_route =~ /create/;
    return [ qw/first_name middle_name last_name orcid url/ ];
}

sub lookup_name {
    my $c = shift;
    my $first = $c->req->json->{first_name};
    my $last = $c->req->json->{last_name};
    $first = Person->meta->db->dbh->quote($first);
    $last = Person->meta->db->dbh->quote($last);
    my $matches = Persons->get_objects( query => [
            \"name_hash(first_name, last_name) = name_hash($first,$last)"
        ]);
    if ($matches && @$matches==1) {
        return $c->redirect_to($matches->[0]->uri($c));
    }
    return $c->reply->not_found unless @$matches;
    return $c->render(json => { matches => [ map $_->as_tree(bonsai => 1), @$matches ] } );
}

=head2 update_rel

Update the relationships.

=cut

sub update_rel {
    my $c = shift;
    my $person = $c->_this_object;
    my $next = $person->uri($c,{tab => 'update_rel_form'});
    $c->stash(tab => "update_rel_form");
    my $json = $c->req->json;

    if (my $pub_id = $json->{delete_publication} || $c->param('delete_publication')) {
        my $con_id = $json->{contributor_id} || $c->param('contributor_id');
        die "person does not match contributor" unless Contributor->new(id => $con_id)->load->person_id == $person->id;
        PublicationContributorMaps->delete_objects({
                contributor_id => $con_id,
                publication_id => $pub_id,
            }) or return $c->update_error("Failed to remove publication");
    } elsif (my $id = $json->{delete_contributor} || $c->param('delete_contributor')) {
        die "person does not match contributor" unless Contributor->new(id => $id)->load->person_id == $person->id;
        Contributors->delete_objects({ id => $id })
            or return $c->update_error("Failed to remove contributor");
        $c->flash(info => "Saved changes.");
    }

    if (my $org = $c->param('organization')) {
        my $organization = Organization->new_from_autocomplete($org) or return $c->update_error("failed to find org $org");
        my $obj = $c->param('publication') or return $c->update_error("Missing publication");
        $obj = $c->str_to_obj($obj) or return $c->update_error("No match for $obj");
        my $pub = $obj->get_publication(autocreate => 1);
        $pub->save(audit_user => $c->audit_user, audit_note => $c->audit_note) unless $pub->id;
        my $role_types = $c->every_param('role_type');
        for my $role_type ( @$role_types ) {
            my $ctr = Contributor->new(
              role_type_identifier    => $role_type,
              person_id               => $person->id,
              organization_identifier => $organization->identifier
            );
            $ctr->load(speculative => 1) or $ctr->save(audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->update_error($ctr->error); 
            $ctr->add_publications($pub);
            $ctr->save(audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->update_error($ctr->error);
        }
    }

    $c->redirect_to($next);
}

sub _pk_to_stashval {
    # Map a primary key column name to a value in the stash
    my $c = shift;
    my $meta = shift;
    my $name = shift;
    my $stash_name = $name;
    $stash_name = "person_identifier" if $name eq 'id';
    return $c->stash($stash_name);
}

sub contributions {
    my $c = shift;
    my $person = $c->_this_object;
    my $role_identifier = $c->stash('role_type_identifier');
    my $resource = $c->stash('resource');
    my $maps = $c->orm->{publication_contributor_map}->{mng}->get_objects(
        query => [
                role_type_identifier => $role_identifier,
                person_id => $person->id,
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
        json => { json => [ map $_->publication->to_object->as_tree(c => $c, bonsai => 1), @$maps ] },
        yaml => sub { shift->render_yaml([ map $_->publication->to_object->as_tree(c => $c, bonsai => 1), @$maps ]) },
        csv => sub { shift->render_csv([ map $_->publication->to_object->as_tree(c => $c, bonsai => 1), @$maps ]) },
        any => sub {
            shift->render,
        }
    );
}
1;

