=head1 NAME

Tuba::RouteDoc -- documentation for a route.

=cut

package Tuba::RouteDoc;
use Mojo::Base qw/-base/;

has 'name';
has 'brief';
has 'description';
has 'params';
has 'note';
has 'tags';

1;

