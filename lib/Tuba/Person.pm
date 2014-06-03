=head1 NAME

Tuba::Person : Controller class for people.

=cut

package Tuba::Person;
use Mojo::Base qw/Tuba::Controller/;
use Algorithm::Permute;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    if ($c->param('all')) {
        $c->stash(objects => Persons->get_objects);
    } else {
        $c->stash(objects => scalar Persons->get_objects(sort_by => 'last_name, first_name', page => $c->page));
        $c->set_pages(Persons->get_objects_count);
    }
    $c->SUPER::list(@_);
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
    my @pieces = split /-/, $name;
    return $c->render_not_found unless @pieces==2;
    my $front = Persons->get_objects(
      query => [first_name => $pieces[0], last_name => $pieces[1]],
      limit => 10
    );
    my $back = Persons->get_objects(
      query => [first_name => $pieces[1], last_name => $pieces[0]],
      limit => 10
    );
    my @found = (@$front, @$back);

    return $c->render_not_found unless @found;
    if (@found==1) {
        return $c->redirect_to('show_person', { person_identifier => $found[0]->id } );
    }

    $c->respond_to(
        json => sub {
            shift->render(json =>{ people =>  [ map $_->as_tree, @found ] }),
        },
        html => sub {
            return $c->render(people => @found);
        },
    );
}

sub redirect_by_orcid {
    my $c = shift;
    my $person = Person->new(orcid => $c->stash('orcid'))->load(speculative => 1) or return $c->render_not_found;
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
    return [ qw/id first_name last_name orcid url/ ] unless $c->current_route =~ /create/;
    return [ qw/first_name last_name orcid url/ ];
}

sub lookup_name {
    my $c = shift;
    my $first = $c->req->json->{first_name};
    my $last = $c->req->json->{last_name};
    my $matches = Persons->get_objects(
        query => [ first_name => $first, last_name => $last ]
    );
    if ($matches && @$matches==1) {
        return $c->redirect_to($matches->[0]->uri($c));
    }
    return $c->render_not_found unless @$matches;
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
        $pub->save(audit_user => $c->user) unless $pub->id;
        my $role_type = $c->param('role_type');
        my $ctr = Contributor->new(
          role_type_identifier    => $role_type,
          person_id               => $person->id,
          organization_identifier => $organization->identifier
        );
        $ctr->load(speculative => 1) or $ctr->save(audit_user => $c->user) or return $c->update_error($ctr->error); 
        $ctr->add_publications($pub);
        $ctr->save(audit_user => $c->user) or return $c->update_error($ctr->error);
    }

    $c->redirect_to($next);
}

=head2 set_replacement

Override to use id instead of identifier.

=cut

sub set_replacement {
    my $c = shift;
    my $table_name = shift;
    my $old_identifier = shift;
    my $new_identifier = shift;
    my $dbh = $c->dbs->dbh;
    $dbh->do(<<SQL, {}, "id=>$new_identifier", $old_identifier) and return 1;
        update audit.logged_actions set changed_fields = ?::hstore
         where action='D' and table_name='$table_name' and row_data->'id' = ?
SQL
    $c->stash(error => $dbh->errstr);
    return 0;
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

1;

