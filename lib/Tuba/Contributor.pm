=head1 NAME

Tuba::Contributor : Controller class for contributors.

=cut

package Tuba::Contributor;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $con = Contributor->new( id => scalar $c->stash('contributor_identifier') )->load( speculative => 1)
      or return $c->render_not_found;
  if (my $p = $con->person) { return $c->redirect_to($p->uri($c)); }
  return $c->redirect_to($con->organization->uri($c));
}

1;

