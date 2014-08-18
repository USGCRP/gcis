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
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $meta);
    $c->SUPER::show(@_);
}

1;

