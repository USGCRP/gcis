=head1 NAME

Tuba::ModelRun : Controller class for model runs.

=cut

package Tuba::ModelRun;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

=head1 show

Show metadata about a model run.

=cut

sub show {
    my $c = shift;
    my $identifier = $c->stash('model_run_identifier');
    my $object = ModelRun->new( identifier => $identifier )
                      ->load( speculative => 1 )
                          or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => ModelRun->meta);
    $c->SUPER::show(@_);
}


1;

