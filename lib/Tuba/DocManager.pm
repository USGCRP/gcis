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
    brief => "Generate a UUID.",
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
  list_report => {
      brief => "Get a list of reports.",
      description => <<DONE,
List the reports in the GCIS, 20 per page.  By default only the first page will be shown.
DONE
      note => <<DONE,
Examine the 'Content-Range' header to determine the number of pages.
DONE
      params => [
          {
            name => "all",
            type => "boolean",
            description => "Set to 1 to get all of the reports.",
          },
          {
            name => "page",
            type => "integer",
            description => "The page number (starting at 1).",
          },
      ],
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
        params => [ map Tuba::RouteParam->new( %$_ ), @{ $entry->{params} } ],
        note => $entry->{note},
    );
}

1;
