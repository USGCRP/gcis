=head1 NAME

Tuba::Exterm - Controller for external terms.

=head1 DESCRIPTION

This controller manages the mapping between external terms and GCIDs.

=cut

package Tuba::Exterm;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub create {
    my $c = shift;
    $c->stash(tab => 'create_form');
    my $lexicon = $c->stash('lexicon');
    my %entry;
    if (my $json = $c->req->json) {
        %entry = (
          term    => $json->{term},
          context => $json->{context},
          lexicon_identifier => $lexicon,
          gcid    => $json->{gcid},
        );
    } else {
        # TODO handle a form too
        return $c->update_error("not implemented");
    }
    my $term = Exterm->new(%entry);
    $term->save(audit_user => $c->user) or return $c->update_error($term->error);
    $c->stash(_this_object => $term);
    return $c->redirect_without_error('create_form');
}

sub find {
    my $c = shift;
    my $term = Exterm->new(
          lexicon_identifier  => $c->stash('lexicon'),
          context  => $c->stash('context'),
          term     => $c->stash('term'),
    );
    $term->load(speculative => 1) or return $c->render_not_found;
    my $gcid = $term->gcid;
    $c->res->headers->location($gcid);
    $c->res->body(qq[See <a href="$gcid">$gcid</a>.]);
    $c->rendered(303);
}

sub remove {
    my $c = shift;
    my $term = Exterm->new(
          lexicon_identifier  => $c->stash('lexicon'),
          context  => $c->stash('context'),
          term     => $c->stash('term'),
    );
    $term->load(speculative => 1) or return $c->render_not_found;
    $term->delete or return $c->render_exception($term->error);
    return $c->render(text => 'ok');
}

1;

