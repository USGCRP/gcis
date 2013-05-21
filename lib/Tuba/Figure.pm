=head1 NAME

Tuba::Figure : Controller class for figures.

=cut

package Tuba::Figure;
use Mojo::Base qw/Mojolicious::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $figures;
    if (my $ch = $c->stash('chapter_identifier')) {
        my $chapter = Chapter->new(identifier => $ch)->load(speculative => 1) or return $c->render_not_found;
        $figures = Figures->get_objects(query => [chapter => $chapter->id], with_objects => ['chapter_obj']);
    } else {
        $figures = Figures->get_objects(with_objects => ['chapter_obj']);
    }
    $c->respond_to(
        json => sub { $c->render_json([ map $_->as_tree, @$figures ]) },
        html => sub { $c->render(template => 'objects', meta => Figure->meta, objects => $figures ) }
    );
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('figure_identifier');
    my $meta = Figure->meta;
    my $object = Figure->new(identifier => $identifier)->load(speculative => 1) or return $c->render_not_found;
    $c->respond_to(
        json => sub { shift->render(json => $object->as_tree) },
        html => sub { shift->render(template => 'object', meta => $meta, objects => $object ) }
    );
}


1;

