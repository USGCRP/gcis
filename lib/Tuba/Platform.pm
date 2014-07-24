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

=head1 list

Show platforms for selected report.

=cut

sub list {
    my $c = shift;
    $c->SUPER::list(@_);
}

1;

