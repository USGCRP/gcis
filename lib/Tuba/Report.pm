=head1 NAME

Tuba::Report : Controller class for reports.

=cut

package Tuba::Report;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $objects = Reports->get_objects;
    my $meta = Report->meta;
    $c->respond_to(
        json => sub { shift->render(json => [ map $_->as_tree, @$objects ]) },
        html => sub { shift->render(template => 'objects', meta => $meta, objects => $objects ) }
    );
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('report_identifier');
    my $meta = Report->meta;
    my $object =
      Report->new( identifier => $identifier )
      ->load( speculative => 1, with => [qw/chapter/] )
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->SUPER::show(@_);
}


1;

