=head1 NAME

Tuba::OrganizationAlternateName : Controller class for Alternate Names for Organizations.

=cut

package Tuba::OrganizationAlternateName;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

=head1 show

Show redirects to the Organization

=cut

sub _default_list_order {
    return "organization_identifier";
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('organization_alternate_name_identifier');

    my $object = OrganizationAlternateName->new( identifier => $identifier )
      ->load( speculative => 1 ) or return $c->reply->not_found;

    $c->redirect_to('show_organization' => { organization_identifier => $object->organization_identifier } );
}

1;

