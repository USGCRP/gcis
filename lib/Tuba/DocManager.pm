=head1 NAME

Tuba::DocManager -- manage documentation for routes.

=cut

package Tuba::DocManager;
use Mojo::Base qw/-base/;
use Tuba::RouteDoc;
use Tuba::RouteParam;
use Mojo::ByteStream qw/b/;

our %RouteDoc = (
  uuid => {
    brief => "Generate a version 4 UUIDs",
    description => b(q[<p>Generate version 4 Universally Unique Identifiers.  The algorithm used for this
    is described <a target="_blank" href="https://en.wikipedia.org/wiki/UUID#Version_4_.28random.29">here</a>.
    </p>]),
    params      => [
        {
          name        => "count",
          type        => "integer",
          description => "Number of UUIDs to generate (max 1000)"
        }
    ]
  },
);

sub find_doc {
    my $c = shift;
    my $route_name = shift;
    my $entry = $RouteDoc{$route_name} or return;
    return Tuba::RouteDoc->new(
        name => $route_name,
        brief => $entry->{brief},
        description => $entry->{description},
        params => [ map Tuba::RouteParam->new( %$_ ), @{ $entry->{params} } ]
    );
}

1;
