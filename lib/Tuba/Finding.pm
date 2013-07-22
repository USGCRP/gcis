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

    if (my $ch = $c->stash('chapter_identifier')) {
        $objects = Findings->get_objects(query => [chapter => $ch], with_objects => ['chapter_obj'],
            sort_by => "ordinal, t1.identifier");
        $c->title('Findings in chapter : '.$ch);
    } else {
        $objects = Findings->get_objects(with_objects => ['chapter_obj'], sort_by => "ordinal, t1.identifier" );
    }

    $c->respond_to(
        json => sub { shift->render(json => [ map $_->as_tree, @$objects ]) },
        html => sub { shift->render(template => 'objects', meta => $meta, objects => $objects ) }
    );
}

sub show {
    my $c = shift;
    my $meta = Finding->meta;
    my $identifier = $c->stash('finding_identifier');
    my $report = $c->stash('report_identifier');
    my $object = Finding->new( identifier => $identifier, report => $report )->load( speculative => 1)
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->respond_to(
        json => sub { shift->render(json => $object->as_tree) },
        nt   => sub { shift->render(template => 'object', meta => $meta, objects => $object ) },
        html => sub { shift->render(template => 'object', meta => $meta, objects => $object ) }
    );
}

1;

