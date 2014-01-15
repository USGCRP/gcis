=head1 NAME

Tuba::Contributor : Controller class for contributors.

=cut

package Tuba::Contributor;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $identifier = $c->stash('contributor_identifier');
    my $con = Contributor->new( id => $identifier )->load( speculative => 1)
      or return $c->render_not_found;
    $c->respond_to(
        json => sub {
            my $c = shift;
            $c->render(json => {
                    person => ($con->person_id ? $con->person->as_tree(c => $c, bonsai => 1) : undef),
                    organization => ($con->organization_identifier ? $con->organization->as_tree(c => $c, bonsai => 1) : undef),
                    role => $con->role_type_identifier
                });
        },
        html => sub {
            my $c = shift;
            $c->render(template => 'object', object => $con, meta => $con->meta);
        }
    );
}

1;

