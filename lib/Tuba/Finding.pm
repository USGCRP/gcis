=head1 NAME

Tuba::Finding : Controller class for findings.

=cut

package Tuba::Finding;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $objects;
    my $meta = Finding->meta;
    my $report_identifier = $c->stash('report_identifier');
    my $all = $c->param('all');
    my @page = $all ? () : (page => $c->page);

    if (my $chapter = $c->stash('chapter')) {
        $objects = Findings->get_objects(
            query => [chapter_identifier => $chapter->identifier, report_identifier => $report_identifier],
            with_objects => ['chapter'],
            @page,
            sort_by => "number, ordinal, t1.identifier");
        $c->set_pages(
            Findings->get_objects_count(
                query => [chapter_identifier => $chapter->identifier, report_identifier => $report_identifier],
                with_objects => ['chapter'],
            )
        ) unless $all;
    } else {
        $objects = Findings->get_objects(
            query => [ report_identifier => $report_identifier ],
            with_objects => ['chapter'],
            sort_by => "number, ordinal, t1.identifier",
            @page,
        );
        $c->set_pages(
            Findings->get_objects_count( query => [ report_identifier => $report_identifier ] )
        ) unless $all;
    }

    $c->stash(objects => $objects);
    $c->stash(extra_cols => [ 'numeric' ]);
    $c->SUPER::list(@_);
}

sub set_title {
    my $c = shift;
    if (my $ch = $c->stash('chapter')) {
        $c->stash(title => sprintf("Findings in chapter %s of %s",$ch->stringify(tiny => 1), $ch->report->title));
    } else {
        $c->stash(title => sprintf("Findings in %s",$c->stash('report')->title));
    }
}

sub update_form {
    my $c = shift;
    my $object = $c->_this_object or return $c->render_not_found;
    $c->verify_consistent_chapter($object) or return $c->render_not_found;
    $c->SUPER::update_form(@_);
}

sub show {
    my $c = shift;
    my $meta = Finding->meta;
    my $identifier = $c->stash('finding_identifier');
    my $report_identifier = $c->stash('report_identifier');
    my $object = $c->_this_object();

    if (!$object && $identifier =~ /^[0-9]+$/ && $c->stash('chapter') ) {
        my $chapter = $c->stash('chapter');
        $object = Finding->new(
          report_identifier  => $c->stash('report_identifier'),
          chapter_identifier => $chapter->identifier,
          ordinal            => $identifier,
        )->load(speculative => 1);
        return $c->redirect_to($object->uri_with_format($c)) if $object;
    };

    return $c->render_not_found unless $object;

    if (!$c->stash('chapter_identifier') && $object->chapter_identifier) {
        $c->stash(chapter_identifier => $object->chapter_identifier);
    }
    return $c->render_not_found unless $c->verify_consistent_chapter($object);

    $c->stash(object => $object);
    $c->SUPER::show(@_);
}

1;

