=head1 NAME

Tuba::Project : Controller class for projects.

=cut

package Tuba::Project;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

=head1 show

Show metadata about a project.

=cut

sub show {
    my $c = shift;
    my $identifier = $c->stash('project_identifier');
    my $meta = Project->meta;
    my $object = Project->new( identifier => $identifier ) ->load( speculative => 1 )
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    $c->SUPER::show(@_);
}


1;

