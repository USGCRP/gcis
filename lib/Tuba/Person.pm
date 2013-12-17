=head1 NAME

Tuba::Person : Controller class for people.

=cut

package Tuba::Person;
use Mojo::Base qw/Tuba::Controller/;
use Algorithm::Permute;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    $c->stash(objects => scalar Persons->get_objects(sort_by => 'last_name, first_name', page => $c->page));
    $c->set_pages(Persons->get_objects_count);
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('person_identifier');
    my $person =
      Person->new( id => $identifier )
      ->load( speculative => 1, with => [qw/contributors/] )
      or return $c->render_not_found;

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

1;

