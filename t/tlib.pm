no warnings 'redefine';

sub Mojo::UserAgent::Transactor::redirect {
  my ($self, $old) = @_;

  # Commonly used codes
  my $res = $old->res;
  my $code = $res->code // '';
  return undef unless grep { $_ eq $code } 301, 302, 303, 307, 308;

  # Fix broken location without authority and/or scheme
  return unless my $location = $res->headers->location;
  $location = Mojo::URL->new($location);
  $location = $location->base($old->req->url)->to_abs unless $location->is_abs;

  # Clone request if necessary
  my $new    = Mojo::Transaction::HTTP->new;
  my $req    = $old->req;
  my $method = uc $req->method;
  if ($code eq 301 || $code eq 307 || $code eq 308) {
    return undef unless my $req = $req->clone;
    $new->req($req);
    $method = 'GET' if $code eq 303 and $method ne 'HEAD';
    $req->headers->remove('Host')->remove('Cookie')->remove('Referer');
  } elsif ($method ne 'HEAD') { $method = 'GET' }

  if (defined(my $accept = $req->headers->accept)) {
     $new->req->headers->accept($accept);
  }

  $new->req->method($method)->url($location);
  return $new->previous($old);
}

1;
