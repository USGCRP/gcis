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

    if (my $chapter_identifier = $c->stash('chapter_identifier')) {
        $objects = Findings->get_objects(
            query => [chapter_identifier => $chapter_identifier, report_identifier => $report_identifier],
            with_objects => ['chapter'],
            @page,
            sort_by => "ordinal, t1.identifier");
        $c->title("Findings in report : $report_identifier, chapter $chapter_identifier");
        $c->set_pages(
            Findings->get_objects_count(
                query => [chapter_identifier => $chapter_identifier, report_identifier => $report_identifier],
                with_objects => ['chapter'],
            )
        ) unless $all;
    } else {
        $objects = Findings->get_objects(
            query => [ report_identifier => $report_identifier ],
            with_objects => ['chapter'],
            sort_by => "ordinal, t1.identifier",
            @page,
        );
        $c->set_pages(
            Findings->get_objects_count( query => [ report_identifier => $report_identifier ] )
        ) unless $all;
        $c->title("Findings in report $report_identifier");
    }

    $c->stash(objects => $objects);
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $meta = Finding->meta;
    my $identifier = $c->stash('finding_identifier');
    my $report_identifier = $c->stash('report_identifier');
    my $object = Finding->new( identifier => $identifier, report_identifier => $report_identifier )->load( speculative => 1)
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->respond_to(
        json => sub { shift->render(json => $object->as_tree) },
        nt   => sub { shift->render(template => 'object', meta => $meta, objects => $object ) },
        html => sub { shift->render(template => 'object', meta => $meta, objects => $object ) }
    );
}

sub create_form {
    my $c = shift;
    $c->SUPER::create_form(@_);
}

1;

