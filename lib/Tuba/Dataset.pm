=head1 NAME

Tuba::Dataset : Controller class for datasets.

=cut

package Tuba::Dataset;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $meta = Dataset->meta;
    my $identifier = $c->stash('dataset_identifier');
    $identifier =~ s/^\s+//;
    $identifier =~ s/\s+$//;
    my $object =
      Dataset->new( identifier => $identifier )->load(speculative => 1)
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->respond_to(
        json => sub { shift->render(json => $object->as_tree) },
        nt   => sub { shift->render(template => 'object', meta => $meta, objects => $object ) },
        html => sub { shift->render(template => 'object', meta => $meta, objects => $object ) }
    );
}


1;

