=head1 NAME

Tuba::GcmdKeyword : Controller class for gcmd keywords.

=cut

package Tuba::GcmdKeyword;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    $c->stash(objects => GcmdKeywords->get_objects(with_objects => 'publications', page => $c->page, per_page => $c->per_page));
    my $count = GcmdKeywords->get_objects_count;
    $c->stash(extra_cols => [qw/label/]);
    $c->set_pages($count);
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $kw = $c->_this_object or $c->reply->not_found;
    $c->stash(object => $kw);
    $c->SUPER::show(@_);
}

sub _guess_object_class {
    return 'Tuba::DB::Object::GcmdKeyword';
}

1;

