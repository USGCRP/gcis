=head1 NAME

Tuba::Scenario : Controller class for scenarios.

=cut

package Tuba::Scenario;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

=head1 show

Show metadata about a scenario.

=cut

sub show {
    my $c = shift;
    my $identifier = $c->stash('scenario_identifier');
    my $object = Scenario->new( identifier => $identifier )
                      ->load( speculative => 1 )
                          or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => Scenario->meta);
    $c->SUPER::show(@_);
}


1;

