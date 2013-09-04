=head1 NAME

Tuba::Contributor : Controller class for contributors.

=cut

package Tuba::Contributor;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $identifier = $c->stash('contributor_identifier');
    my $con = Contributor->new( id => $identifier )->load( speculative => 1)
      or return $c->render_not_found;
    if (my $person = $con->person) {
        return $c->redirect_to($person->uri($c));
    }
    if (my $org = $con->organization) {
        return $c->redirect_to($org->uri($c));
    }
    return $c->render_not_found;
}

1;

