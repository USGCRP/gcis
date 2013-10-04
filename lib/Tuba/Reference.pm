=head1 NAME

Tuba::Reference : Controller class for references.

=cut

package Tuba::Reference;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $pub = $c->current_report->get_publication or return $c->render_not_found;
    my $refs = References->get_objects(
      require_objects => 'publication_map',
      query           => [child => $pub->id],
      page            => $c->page,
    );
    my $count = References->get_objects_count(
      require_objects => 'publication_map',
      query           => [child => $pub->id],
      page            => $c->page,
    );
    $c->set_pages($count);
    $c->stash(title => "References for ".$c->current_report->identifier." report");
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('reference_identifier');
    my $reference = Reference->new(identifier => $identifier);
    $reference->load(speculative => 1) or return $c->render_not_found;
    $c->stash( object => $reference);
    $c->SUPER::show(@_);
}

1;

