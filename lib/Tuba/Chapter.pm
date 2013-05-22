=head1 NAME

Tuba::Report : Controller class for chapters.

=cut

package Tuba::Chapter;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $objects = Chapters->get_objects;
    $c->respond_to(
        json => sub { shift->render_json([ map $_->as_tree, @$objects ]) },
        html => sub { shift->render(template => 'objects', meta => Chapter->meta, objects => $objects ) }
    );
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('chapter_identifier');
    my $chapter =
      Chapter->new( identifier => $identifier )
      ->load( speculative => 1, with => [qw/figure report_obj/] )
      or return $c->render_not_found;

    $c->respond_to(
        json => sub { shift->render_json($chapter->as_tree) },
        html => sub { shift->render(template => "object", meta => Chapter->meta, object => $chapter) }
    );
}

1;

