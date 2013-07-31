=head1 NAME

Tuba::Organization : Controller class for organizations.

=cut

package Tuba::Organization;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $objects = Organizations->get_objects(sort_by => 'identifier');
    my $meta = Organization->meta;
    $c->respond_to(
        json => sub { shift->render(json => [ map $_->{org}->as_tree, @$objects ]) }, # TODO
        html => sub { shift->render(template => 'organization/objects', meta => $meta, objects => $objects ) }
    );
}

sub show {
    my $c = shift;
    my $meta = Organization->meta;
    my $identifier = $c->stash('organization_identifier');
    my $object = Organization->new( identifier => $identifier )->load( speculative => 1 )
      or return $c->render_not_found;
    $c->stash(object => $object);
    return $c->SUPER::show(@_);
}

1;

