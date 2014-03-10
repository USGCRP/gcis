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
  my $format = $c->stash('format');
  if (my $p = $con->person) {
      my $uri = $p->uri($c);
      $uri .= ".$format" if $format;
      return $c->redirect_to($uri);
  }
  my $uri = $con->organization->uri($c);
  $uri .= ".$format" if $format;

  return $c->redirect_to($uri);
}

1;

