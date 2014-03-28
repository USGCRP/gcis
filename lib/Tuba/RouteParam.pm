=head1 NAME

Tuba::RouteParam -- a single parameter for a route.

=cut

package Tuba::RouteParam;
use Mojo::Base qw/-base/;

has 'name';
has 'type';
has 'description';

1;

