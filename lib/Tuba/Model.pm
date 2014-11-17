=head1 NAME

Tuba::Model : Controller class for models.

=cut

package Tuba::Model;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

=head1 show

Show metadata about a model.

=cut

sub show {
    my $c = shift;
    my $identifier = $c->stash('model_identifier');
    my $object = Model->new( identifier => $identifier )
                      ->load( speculative => 1 )
                          or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => Model->meta);
    $c->SUPER::show(@_);
}


1;

