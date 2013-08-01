=head1 NAME

Tuba::Journal : Controller class for journals.

=cut

package Tuba::Journal;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $objects = Journals->get_objects(sort_by => 'identifier');
    my $meta = Journal->meta;
    $c->respond_to(
        json => sub { shift->render(json => [ map $_->as_tree, @$objects ]) },
        html => sub { shift->render(template => 'objects', meta => $meta, objects => $objects ) }
    );
}

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

1;

