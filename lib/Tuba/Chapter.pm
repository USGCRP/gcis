=head1 NAME

Tuba::Chapter : Controller class for chapters.

=cut

package Tuba::Chapter;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::Contributor;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $report = $c->stash('report_identifier');
    my $all = $c->param('all');
    my @page = $all ? () : (page => $c->page);
    $c->stash(objects => Chapters->get_objects(query => [ report_identifier => $report ],
             with_objects => [qw/figures findings tables/],
             multi_many_ok => 1,
             sort_by => 'chapter.number',
             @page,
         )
    );
    $c->set_pages( Chapters->get_objects_count( query => [ report_identifier => $report ] )) unless $all;
    $c->title('Chapters in report '.$report);
    $c->stash(cols => [
        qw/number identifier report figures findings tables/
        ]);
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('chapter_identifier');
    my $report = $c->stash('report_identifier');
    my $chapter =
      Chapter->new( identifier => $identifier, report_identifier => $report )
          ->load( speculative => 1, with => [qw/figures findings report/] );
    if (!$chapter && $identifier =~ /^\d+$/) {
      $chapter = Chapter->new( number => $identifier, report_identifier => $report )
        ->load( speculative => 1, with => [qw/figures findings report/] );
      if ($chapter) {
        $c->stash(chapter_identifier => $chapter->identifier);
        return $c->redirect_to( $c->current_route, { chapter_identifier => $chapter->identifier } );
      }
    }
    return $c->render_not_found unless $chapter;

    $c->stash(object => $chapter);
    $c->stash(meta => Chapter->meta);
    $c->stash(relationships => [ map Chapter->meta->relationship($_), qw/report figures findings tables/ ]);
    $c->SUPER::show(@_);
}

sub update_rel_form {
    my $c = shift;
    $c->stash(relationships => [ map Chapter->meta->relationship($_), qw/report figures findings tables/ ]);
    $c->stash(controls => {
            figures  => { template => 'one_to_many', },
            findings => { template => 'one_to_many' },
            tables   => { template => 'one_to_many' },
        });
    $c->SUPER::update_rel_form(@_);
}

sub make_tree_for_list {
    my $c = shift;
    my $chapter = shift;
    my $uri = $chapter->uri($c);
    my $href = $uri->clone->to_abs;
    $href .= ".".$c->stash('format') if $c->stash('format');
    return +{
        number     => $chapter->number,
        title      => $chapter->title,
        uri        => $uri,
        identifier => $chapter->identifier,
        href       => $href,
    };
}

sub make_tree_for_show {
    my ($c, $chapter) = @_;
    my $pub = $chapter->get_publication(autocreate => 1);
    return {
      number            => $chapter->number,
      files             => [map +{uri => $_->uri($c)}, $pub->files],
      figures           => [map +{$c->Tuba::Figure::common_tree_fields($_)}, $chapter->figures],
      findings          => [map +{$c->Tuba::Finding::common_tree_fields($_)}, $chapter->findings],
      tables            => [map +{$c->Tuba::Table::common_tree_fields($_)}, $chapter->tables],
      report_identifier => $chapter->report_identifier,
      identifier        => $chapter->identifier,
      contributors      => [map +{$c->Tuba::Contributor::common_tree_fields($_)}, $pub->contributors],
      url               => $chapter->url,
      title             => $chapter->title,
      $c->common_tree_fields($chapter),
      }
}

1;

