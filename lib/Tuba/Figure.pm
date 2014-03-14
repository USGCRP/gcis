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
    my @page = $all ? () : (page => $c->page, per_page => $c->per_page);
    if (my $ch = $c->stash('chapter_identifier')) {
        $figures = Figures->get_objects(
            query => [chapter_identifier => $ch, report_identifier => $report_identifier], with_objects => ['chapter'],
            @page,
            sort_by => "number, ordinal, t1.identifier",
            );
        $c->set_pages(Figures->get_objects_count(
            query => [chapter_identifier => $ch, report_identifier => $report_identifier], with_objects => ['chapter'],
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
    my $object = Figure->new(
      identifier        => $c->stash('figure_identifier'),
      report_identifier => $c->stash('report_identifier')
      )->load(speculative => 1, with => [qw/chapter images/])
      or return $c->render_not_found;
    if (my $chapter_identifier = $object->chapter_identifier) {
        if (!$c->stash('chapter_identifier')) {
            $c->stash(chapter_identifier => $chapter_identifier);
        }
    }
    $c->stash(object => $object);
    $c->stash(meta => Figure->meta);
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
    $c->stash(tab => "update_rel_form");
    my $json = $c->req->json;

    $object->meta->error_mode('return');

    if (my $new = $c->param('new_image')) {
        my $img = $c->Tuba::Search::autocomplete_str_to_object($new);
        $object->add_images($img);
        $object->save(audit_user => $c->user) or return $c->update_error($object->error);
    }
    if (my $new = $json->{add_image_identifier}) {
        my $img = Image->new(identifier => $new)->load(speculative => 1)
            or return $c->update_error("Image $new not found");
        $object->add_images($img);
        $object->save(audit_user => $c->user) or return $c->update_error($object->error);
    }

    my $report_identifier = $c->stash('report_identifier');
    my @delete_images = $c->param('delete_image');
    if (my $nother = $json->{delete_image_identifier}) {
        push @delete_images, $nother;
    }
    for my $id (@delete_images) {
        ImageFigureMaps->delete_objects({ image_identifier => $id, figure_identifier => $object->identifier, report_identifier => $report_identifier });
        $c->flash(message => 'Saved changes');
    }

    return $c->SUPER::update_rel(@_);
}

1;

