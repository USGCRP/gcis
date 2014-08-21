=head1 NAME

Tuba::Platform : Controller class for platforms.

=cut

package Tuba::Platform;
use Tuba::DB::Objects qw/-nicknames/;
use Mojo::Base qw/Tuba::Controller/;

=head1 ROUTES

=head1 show

Show metadata about a platform.

=cut

sub show {
    my $c = shift;
    my $identifier = $c->stash('platform_identifier');
    my $meta = Platform->meta;
    my $object = Platform->new( identifier => $identifier ) ->load( speculative => 1 )
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    $c->SUPER::show(@_);
}

=head1 update_rel

Update relationships for this platform.

=cut

sub update_rel {
    my $c = shift;
    my $platform = $c->_this_object;
    $c->stash(tab => "update_rel_form");

    if (my $json = $c->req->json) {
        if (my $add = $json->{add}) {
            $add->{platform_identifier} = $platform->identifier;
            my $obj = InstrumentInstance->new( %$add );
            $obj->load(speculative => 1);
            $obj->save(audit_user => $c->user) or return $c->update_error($obj->error);
        }
    }
    # TODO : handle form submission too

    return $c->redirect_without_error("update_rel_form");
}

1;

