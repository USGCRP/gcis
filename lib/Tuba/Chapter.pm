=head1 NAME

Tuba::Chapter : Controller class for chapters.

=cut

package Tuba::Chapter;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $report = $c->stash('report_identifier');
    my $all = $c->param('all');
    my @page = $all ? () : (page => $c->page);
    $c->stash(objects => Chapters->get_objects(query => [ report => $report ],
             with_objects => ['figure' ],
             sort_by => 'chapter.number',
             @page,
         )
    );
    $c->set_pages( Chapters->get_objects_count( query => [ report => $report ] )) unless $all;
    $c->title('Chapters in report '.$report);
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('chapter_identifier');
    my $report = $c->stash('report_identifier');
    my $chapter =
      Chapter->new( identifier => $identifier, report => $report )
      ->load( speculative => 1, with => [qw/figure finding report_obj/] )
      or return $c->render_not_found;

    $c->stash(object => $chapter);
    $c->stash(meta => Chapter->meta);
    $c->SUPER::show(@_);
}

1;

