=head1 NAME

Tuba::Person : Controller class for people.

=cut

package Tuba::Person;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $objects = Persons->get_objects;
    $_->load_foreign for @$objects;
    $c->respond_to(
        json => sub { shift->render(json => [ map $_->as_tree, @$objects ]) },
        html => sub { shift->render(template => 'person/objects', meta => Person->meta, objects => $objects ) }
    );
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('person_identifier');
    my $person =
      Person->new( id => $identifier )
      ->load( speculative => 1, with => [qw/contributor/] )
      or return $c->render_not_found;

    $c->respond_to(
        json => sub { shift->render(json => $person->as_tree ) },
        nt    => sub { shift->render(template => "object", meta => Person->meta, object => $person) },
        html => sub { shift->render(template => "person/object", meta => Person->meta, object => $person) }
    );
}

1;

