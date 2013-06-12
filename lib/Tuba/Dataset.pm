=head1 NAME

Tuba::Dataset : Controller class for datasets.

=cut

package Tuba::Dataset;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $objects = Datasets->get_objects;
    my $meta = Dataset->meta;
    $c->respond_to(
        json => sub { shift->render(json => [ map $_->as_tree, @$objects ]) },
        html => sub { shift->render(template => 'objects', meta => $meta, objects => $objects ) }
    );
}

sub show {
    my $c = shift;
    my $meta = Dataset->meta;
    my $identifier = $c->stash('dataset_identifier');
    my $object =
      Dataset->new( identifier => $identifier )->load( speculative => 1)
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->respond_to(
        json => sub { shift->render(json => $object->as_tree) },
        html => sub { shift->render(template => 'object', meta => $meta, objects => $object ) }
    );
}


1;

