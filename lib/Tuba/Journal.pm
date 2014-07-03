=head1 NAME

Tuba::Journal : Controller class for journals.

=cut

package Tuba::Journal;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $meta = Journal->meta;
    my $identifier = $c->stash('journal_identifier');
    my $object =
      Journal->new( identifier => $identifier )->load( speculative => 1)
      or return $c->render_not_found_or_redirect;
    $c->stash(object => $object);
    $c->SUPER::show(@_);
}

sub make_tree_for_show {
    my $c = shift;
    my $obj = shift;
    my $h = $c->SUPER::make_tree_for_show($obj);
    $h->{articles} = [ map $_->as_tree(c => $c), $obj->articles ];
    return $h;
}

sub list {
    my $c = shift;
    if ($c->param('all')) {
        $c->stash(objects => Journals->get_objects);
    }
    $c->SUPER::list(@_);
}

sub _default_order {
    my $c = shift;
    return qw/identifier title online_issn print_issn url publisher country notes/;
}

1;

