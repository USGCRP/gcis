=head1 NAME

Tuba::File : Controller class for files.

=cut

package Tuba::File;
use Mojo::Base qw/Mojolicious::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

#sub list {
#    my $c = shift;
#    $c->respond_to(
#        json => sub { $c->render_json([ map $_->as_tree, @$files ]) },
#        html => sub { $c->render(template => 'objects', meta => file->meta, objects => $files ) }
#    );
#}

sub show {
    my $c = shift;
    my $identifier = $c->stash('file_identifier');
    my $meta = File->meta;
    my $object = File->new(identifier => $identifier)->load(speculative => 1 ) or return $c->render_not_found;
    $c->respond_to(
        json => sub { shift->render(json => $object->as_tree) },
        html => sub { shift->render(template => 'file/object', meta => $meta, object => $object ) }
    );
}


1;

