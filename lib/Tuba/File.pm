=head1 NAME

Tuba::File : Controller class for files.

=cut

package Tuba::File;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    return $c->reply->not_found;
    $c->stash(objects => Files->get_objects(with_objects => 'publications', page => $c->page, per_page => $c->per_page));
    my $count = Files->get_objects_count;
    $c->set_pages($count);
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('file_identifier');
    my $meta = File->meta;
    my $object = File->new(identifier => $identifier)->load(speculative => 1 ) or return $c->render_not_found_or_redirect;
    $c->stash(object => $object);
    $c->SUPER::show(@_);
}


1;

