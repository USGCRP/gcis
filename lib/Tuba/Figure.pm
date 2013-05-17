=head1 NAME

Tuba::Figure : Controller class for figures.

=cut

package Tuba::Figure;
use Mojo::Base qw/Mojolicious::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $figures;
    if (my $ch = $c->stash('chapter_name')) {
        my $chapter = Chapter->new(short_name => $ch)->load(speculative => 1) or return $c->render_not_found;
        $figures = Figures->get_objects(query => [chapter => $chapter->id], with_objects => ['chapter_obj']);
    } else {
        $figures = Figures->get_objects(with_objects => ['chapter_obj']);
    }
    $c->respond_to(
        json => sub { $c->render_json([ map $_->as_tree, @$figures ]) },
        html => sub { $c->render(template => 'objects', meta => Figure->meta, objects => $figures ) }
    );
}

1;

