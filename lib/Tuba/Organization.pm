=head1 NAME

Tuba::Organization : Controller class for organizations.

=cut

package Tuba::Organization;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $objects = Organizations->get_objects(with_objects => ["organization_type_obj"]);
    my $meta = Organization->meta;
    $_->load_foreign for @$objects;
    $c->respond_to(
        json => sub { shift->render(json => [ map $_->{org}->as_tree, @$objects ]) }, # TODO
        html => sub { shift->render(template => 'organization/objects', meta => $meta, objects => $objects ) }
    );
}

sub show {
    my $c = shift;
    my $meta = Organization->meta;
    my $identifier = $c->stash('organization_identifier');
    my $object = Organization->new( fk => $identifier )->load( speculative => 1 )
      or return $c->render_not_found;
    $object->load_foreign;
    $c->stash(object => $object);
    $c->respond_to(
        json => sub { shift->render(json => $object->as_tree) }, # TODO
        html => sub { shift->render(template => 'organization/object', meta => $meta, objects => $object ) }
    );
}

1;

