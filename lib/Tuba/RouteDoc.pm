=head1 NAME

Tuba::RouteDoc -- documentation for a route.

=cut

package Tuba::RouteDoc;
use Mojo::Base qw/-base/;

has 'name';
has 'description';
has 'params';

1;

