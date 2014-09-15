=head1 NAME

Tuba::InstrumentInstance : Controller class for instrument instances.

=cut

package Tuba::InstrumentInstance;
use Tuba::DB::Objects qw/-nicknames/;
use Mojo::Base qw/Tuba::Controller/;

=head1 ROUTES

=head1 show

Show metadata about an instrument instance : this is an instrument on a platform.

=cut

sub show {
    my $c = shift;
    my $platform_identifier = $c->stash('platform_identifier') or die "missing platform";
    my $instrument_identifier = $c->stash('instrument_instance_identifier') or die "missing instrument";
    my $object = InstrumentInstance->new(
      platform_identifier   => $platform_identifier,
      instrument_identifier => $instrument_identifier
      )->load(speculative => 1)
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->stash(meta => $object->meta);
    $c->SUPER::show(@_);
}

sub list {
    my $c = shift;
    my @page = $c->param('all') ? () : (page => $c->page, per_page => $c->per_page);
    my $objs;
    if (my $platform_identifier = $c->stash('platform_identifier')) {
      $objs = InstrumentInstances->get_objects(
        query => [platform_identifier => $platform_identifier],
        @page, sort_by => "instrument_identifier"
      );
      $c->set_pages(
        InstrumentInstances->get_objects_count(
          query => [platform_identifier => $platform_identifier],
        )
      );
    } else {
      $objs = InstrumentInstances->get_objects(
          @page, sort_by => "platform_identifier,instrument_identifier"
      );
      $c->set_pages(InstrumentInstances->get_objects_count());
    }
    $c->stash(objects => $objs);
    $c->SUPER::list(@_);
}

1;

