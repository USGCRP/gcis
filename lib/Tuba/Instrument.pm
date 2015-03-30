=head1 NAME

Tuba::Instrument : Controller class for instruments.

=cut

package Tuba::Instrument;
use Tuba::DB::Objects qw/-nicknames/;
use Mojo::Base qw/Tuba::Controller/;

=head1 ROUTES

=head1 show

Show metadata about a instrument.

=cut

sub show {
    my $c = shift;
    my $identifier = $c->stash('instrument_identifier');
    my $meta = Instrument->meta;
    my $object = Instrument->new( identifier => $identifier ) ->load( speculative => 1 )
      or return $c->reply->not_found;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    $c->SUPER::show(@_);
}

sub make_tree_for_show {
    my $c = shift;
    my $instrument = shift;
    my $obj = $c->SUPER::make_tree_for_show($instrument, @_);
    $obj->{platforms} = [
        map +{
            uri => "/platform/".$_->identifier,
            identifier => $_->identifier,
            name => $_->name,
            description => $_->description,
            description_attribution => $_->description,
        }, $instrument->platforms
    ];
    return $obj;
}

sub update_rel_form {
    my $c = shift;
    $c->stash(relationships => [ map Instrument->meta->relationship($_), qw/platforms/ ]);
    $c->stash(controls => {
            platforms => { template => 'many_to_many' },
        });
    $c->SUPER::update_rel_form(@_);
}

sub update_rel {
    my $c = shift;
    my $instrument = $c->_this_object;
    $c->stash(tab => "update_rel_form");
    if (my $platform_id = $c->param('delete_map_platforms')) {
        my $map = Tuba::DB::Object::InstrumentInstance->new(
                platform_identifier => $platform_id,
                instrument_identifier => $instrument->identifier)->load(
                speculative => 1) or return $c->redirect_without_error("Could not find $platform_id");
        $map->delete or return $c->update_error($map->error);
        $c->flash(info => "Deleted $platform_id");
    }
    return $c->SUPER::update_rel(@_);
}

1;

