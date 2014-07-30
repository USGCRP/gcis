=head1 NAME

Tuba::Lexicon - Controller for lexicons.

=head1 DESCRIPTION

This controller manages the mapping between external identifiers and GCIDs.

=cut

package Tuba::Lexicon;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub create {
    my $c = shift;
    $c->stash(tab => 'create_form');
    my $argot = $c->stash('argot');
    my %entry;
    if (my $json = $c->req->json) {
        %entry = (
          argot      => $argot,
          term_class => $json->{term_class},
          term       => $json->{term},
          gcid       => $json->{gcid},
        );
    } else {
        # TODO handle a form too
        return $c->update_error("not implemented");
    }
    my $extern = Lexicon->new(%entry);
    $extern->save(audit_user => $c->user) or return $c->update_error($extern->error);
    $c->stash(_this_object => $extern);
    return $c->redirect_without_error('create_form');
}

sub find {
    my $c = shift;
    my $extern = Lexicon->new(
          argot       => $c->stash('argot'),
          term_class  => $c->stash('term_class'),
          term        => $c->stash('term'),
    );
    $extern->load(speculative => 1) or return $c->render_not_found;
    my $gcid = $extern->gcid;
    $c->res->headers->location($gcid);
    $c->res->body(qq[See <a href="$gcid">$gcid</a>.]);
    $c->rendered(303);
}

sub remove {
    my $c = shift;
    my $extern = Lexicon->new(
          argot       => $c->stash('argot'),
          term_class  => $c->stash('term_class'),
          term        => $c->stash('term'),
    );
    $extern->load(speculative => 1) or return $c->render_not_found;
    $extern->delete or return $c->render_exception($extern->error);
    return $c->render(text => 'ok');
}

1;

