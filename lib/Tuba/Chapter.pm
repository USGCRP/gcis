=head1 NAME

Tuba::Chapter : Controller class for chapters.

=cut

package Tuba::Chapter;
use Mojo::Base qw/Mojolicious::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $objects;
    my $objects = Chapter->get_objects;
    $c->respond_to(
        json => sub { shift->render_json([ map $_->as_json, @$objects ]) },
        html => sub { shift->render(template => 'objects', meta => Chapter->meta, objects => $objects ) }
    );
}

sub view {
    my $c = shift;
    my $short_name = $c->stash('short_name');
    my $chapter = Chapter->new(short_name => $short_name)->load;
    $c->respond_to(
        json => sub { shift->render_json($chapter->to_json) },
        html => sub { shift->render(template => "object", meta => Chapter->meta, object => $chapter) }
    );
}

1;

