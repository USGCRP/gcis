=head1 NAME

Tuba::Figure : Controller class for figures.

=cut

package Tuba::Figure;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $figures;
    if (my $ch = $c->stash('chapter_identifier')) {
        $figures = Figures->get_objects(query => [chapter => $ch], with_objects => ['chapter_obj'],
            sort_by => "number, ordinal, t1.identifier");
        $c->title('figures in chapter');
    } else {
        $figures = Figures->get_objects(with_objects => ['chapter_obj'], sort_by => "number, ordinal, t1.identifier" );
    }

    $c->respond_to(
        json => sub { $c->render(json => [ map $_->as_tree, @$figures ]) },
        html => sub { $c->render(template => 'figure/objects', meta => Figure->meta, objects => $figures ) }
    );
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('figure_identifier');
    my $meta = Figure->meta;
    my $object = Figure->new(identifier => $identifier)->load(speculative => 1, with => [qw/chapter_obj image/]) or return $c->render_not_found;
    $c->respond_to(
        json => sub { shift->render(json => $object->as_tree) },
        nt   => sub { shift->render(template => 'object',        meta => $meta, object => $object ) },
        html => sub { shift->render(template => 'figure/object', meta => $meta, object => $object ) }
    );
}

sub redirect_to_identifier {
    my $c = shift;
    my $chapter_number = $c->stash('chapter_number');
    my $figure_number = $c->stash('figure_number');
    my $found = Figures->get_objects(
            with_objects => ['chapter_obj'],
            query => [
                'chapter.number' => $chapter_number,
                'ordinal' => $figure_number,
            ]
        );
    return $c->render_not_found unless $found && @$found;
    return $c->redirect_to( 'show_figure' => { figure_identifier => $found->[0]->identifier } );
}

1;

