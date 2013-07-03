=head1 NAME

Tuba::Publication : Controller class for publications.

=cut

package Tuba::Publication;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $identifier = $c->stash('publication_identifier');
    my $object =
      Publication->new( id => $identifier )->load( speculative => 1)
      or return $c->render_not_found;
    my $table = $object->publication_type_obj->table;
    my %defaults = %{ $c->app->defaults };
    return $c->redirect_to( 'show_'.$table, { %defaults, $table.'_identifier' => $object->fk } );
}

1;

