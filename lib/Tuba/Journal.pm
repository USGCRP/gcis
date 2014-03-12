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
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->SUPER::show(@_);
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

