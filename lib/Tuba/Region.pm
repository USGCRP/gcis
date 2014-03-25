=head1 NAME

Tuba::Region : Controller class for regions.

=cut

package Tuba::Region;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    $c->stash(objects => Regions->get_objects(with_objects => 'publications', page => $c->page));
    my $count = Regions->get_objects_count;
    $c->stash(extra_cols => [qw/label/]);
    $c->set_pages($count);
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $kw = $c->_this_object or $c->render_not_found;
    $c->stash(object => $kw);
    $c->SUPER::show(@_);
}

1;

