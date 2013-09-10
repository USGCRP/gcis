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
    my $all = $c->param('all');
    my @page = $all ? () : (page => $c->page);
    if (my $ch = $c->stash('chapter_identifier')) {
        $figures = Figures->get_objects(
            query => [chapter => $ch, report_identifier => $report_identifier], with_objects => ['chapter'],
            @page,
            sort_by => "number, ordinal, t1.identifier",
            );
        $c->set_pages(Figures->get_objects_count(
            query => [chapter => $ch, report_identifier => $report_identifier], with_objects => ['chapter'],
            )) unless $all;
    } else {
        $figures = Figures->get_objects(
           with_objects => ['chapter'], sort_by => "number, ordinal, t1.identifier",
           query => [ report_identifier => $report_identifier ],
           @page,
       );
       $c->set_pages(Figures->get_objects_count(
           query => [ report_identifier => $report_identifier ])
       ) unless $all;
    }
    
    $c->stash(objects => $figures);
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $report_identifier = $c->stash('report_identifier');
    my $identifier = $c->stash('figure_identifier');
    my $meta = Figure->meta;
    my $object = Figure->new(identifier => $identifier, report_identifier => $report_identifier)
        ->load(speculative => 1, with => [qw/chapter images/]) or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    $c->SUPER::show(@_);
}

sub redirect_to_identifier {
    my $c = shift;
    my $chapter_number = $c->stash('chapter_number');
    my $figure_number = $c->stash('figure_number');
    my $found = Figures->get_objects(
            with_objects => ['chapter'],
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
    $c->stash(relationships => [ map Figure->meta->relationship($_), qw/images/ ]);
    $c->stash(controls => {
            images => sub {
                my ($c,$obj) = @_;
                +{
                    template => 'image',
                    params => { }
                  }
              }
        });
    $c->SUPER::update_rel_form(@_);
}

sub update_rel {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    my $next = $object->uri($c,{tab => 'update_rel_form'});
    $object->meta->error_mode('return');
    if (my $new = $c->param('new_image')) {
        my $img = $c->Tuba::Search::autocomplete_str_to_object($new);
        $object->add_images($img);
        $object->save(audit_user => $c->user) or do {
            $c->flash(error => $object->error);
            return $c->redirect_to($next);
        };
    }

    my $report_identifier = $c->stash('report_identifier');
    for my $id ($c->param('delete_image')) {
        ImageFigureMaps->delete_objects({ image_identifier => $id, figure_identifier => $object->identifier, report_identifier => $report_identifier });
        $c->flash(message => 'Saved changes');
    }

    return $c->redirect_to($next);
}

1;

