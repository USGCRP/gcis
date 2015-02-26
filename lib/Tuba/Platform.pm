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
      or return $c->reply->not_found;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    $c->SUPER::show(@_);
}

sub make_tree_for_show {
    my $c = shift;
    my $platform = shift;
    my $obj = $c->SUPER::make_tree_for_show($platform, @_);
    $obj->{instruments} = [
        map +{
            uri => "/instrument/".$_->identifier,
            identifier => $_->identifier,
            name => $_->name,
            description => $_->description,
            description_attribution => $_->description,
        }, $platform->instruments
    ];
    return $obj;
}

=head1 update_rel

Update relationships for this platform.

Sample JSON payloads :

    add :
        instrument_identifier : bar
    
    del :
        Instrument_identifier : baz

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
        if (my $del = $json->{del}) {
            $del->{platform_identifier} = $platform->identifier;
            my $obj = InstrumentInstance->new( %$del );
            $obj->delete;
        }
    }
    if (my $instrument_id = $c->param('delete_map_instruments')) {
        my $map = Tuba::DB::Object::InstrumentInstance->new(
                platform_identifier => $platform->identifier,
                instrument_identifier => $instrument_id)->load(
                speculative => 1) or return $c->redirect_without_error("Could not find $instrument_id");
        $map->delete or return $c->update_error($map->error);
        $c->flash(info => "Deleted $instrument_id");
    }
    $c->SUPER::update_rel(@_);

    return $c->redirect_without_error("update_rel_form");
}

sub _default_controls {
    my $c = shift;
    return (
        $c->SUPER::_default_controls(),
        platform_type_identifier => { template => 'select',
            params => { values => [map $_->identifier, @{ PlatformTypes->get_objects(all => 1) } ] } },
    );
}

sub update_rel_form {
    my $c = shift;
    $c->stash(relationships => [ map Platform->meta->relationship($_), qw/instruments/ ]);
    $c->stash(controls => {
            instruments => { template => 'many_to_many' },
        });
    $c->SUPER::update_rel_form(@_);
}

1;

