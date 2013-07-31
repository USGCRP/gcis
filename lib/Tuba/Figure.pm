=head1 NAME

Tuba::Figure : Controller class for figures.

=cut

package Tuba::Figure;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $figures;
    my $report_identifier = $c->stash('report_identifier');
    if (my $ch = $c->stash('chapter_identifier')) {
        $figures = Figures->get_objects(
            query => [chapter => $ch, report => $report_identifier], with_objects => ['chapter_obj'],
            sort_by => "number, ordinal, t1.identifier",
            );
        $c->title('figures in chapter');
    } else {
        $figures = Figures->get_objects(with_objects => ['chapter_obj'], sort_by => "number, ordinal, t1.identifier",
       query => [ report => $report_identifier ] );
    }

    $c->respond_to(
        json => sub { $c->render(json => [ map $_->as_tree, @$figures ]) },
        html => sub { $c->render(template => 'figure/objects', meta => Figure->meta, objects => $figures ) }
    );
}

sub show {
    my $c = shift;
    my $report = $c->stash('report_identifier');
    my $identifier = $c->stash('figure_identifier');
    my $meta = Figure->meta;
    my $object = Figure->new(identifier => $identifier, report => $report)
        ->load(speculative => 1, with => [qw/chapter_obj image_objs/]) or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    $c->SUPER::show(@_);
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

sub update_form {
    my $c = shift;
    $c->SUPER::update_form(@_);
}

sub update_rel_form {
    my $c = shift;
    $c->stash(relationships => [ map Figure->meta->relationship($_), qw/report_obj chapter_obj image_objs/ ]);
    $c->stash(controls => {
            image_objs => sub {
                my ($c,$obj) = @_;
                +{
                template => 'image',
                params => {
                }
            } }
        });
    $c->SUPER::update_rel_form(@_);
}

sub update_rel {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    $object->meta->error_mode('return');
    if (my $new = $c->param('new_image')) {
        my $img = $c->Tuba::Search::autocomplete_str_to_object($new);
        $object->add_image_objs($img);
        $object->save(audit_user => $c->user) or do {
            $c->flash(error => $object->error);
            return $c->render(template => 'update_rel_form');
        };
    }

    for my $id ($c->param('delete_image')) {
        ImageFigureMaps->delete_objects({ image => $id, figure => $object->identifier });
        $c->flash(message => 'Saved changes');
    }

    $c->_redirect_to_view($object);
}

1;

