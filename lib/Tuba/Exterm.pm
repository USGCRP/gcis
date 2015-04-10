=head1 NAME

Tuba::Exterm - Controller for external terms.

=head1 DESCRIPTION

This controller manages the mapping between external terms and GCIDs.

=cut

package Tuba::Exterm;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

# create allows updates too; it just assigns lexicon/context/term to a GCID.
sub create {
    my $c = shift;
    $c->stash(tab => 'create_form');
    my $lexicon = $c->stash('lexicon_identifier');
    my %entry;
    my $term;
    # PUT uses the URL (stash), POST uses the payload (json)
    if (my $json = $c->req->json) {
        %entry = (
          term    => $json->{term} // $c->stash('term'),
          context => $json->{context} // $c->stash('context'),
          lexicon_identifier => $lexicon,
        );
        $term = Exterm->new(%entry);
        $term->load(speculative => 1);
        $term->gcid($json->{gcid});
    } else {
        # NB: forms are handled through lexicon/rel
        return $c->update_error("missing JSON to add exterm");
    }
    $term->save(audit_user => $c->user) or return $c->update_error($term->error);
    $c->stash(_this_object => $term);
    return $c->redirect_without_error('create_form');
}

sub find {
    my $c = shift;
    my $term = Exterm->new(
          lexicon_identifier  => $c->stash('lexicon_identifier'),
          context  => $c->stash('context'),
          term     => $c->stash('term'),
    );
    $term->load(speculative => 1) or return $c->reply->not_found;
    my $gcid = $term->gcid;
    $c->res->headers->location($gcid);
    $c->respond_to(
        html => { code => 303, text => qq[See <a href="$gcid">$gcid</a>.]},
        json => { code => 303, json => { gcid => $gcid } }
    );

    $c->rendered(303);
}

sub remove {
    my $c = shift;
    my $term = Exterm->new(
          lexicon_identifier  => $c->stash('lexicon_identifier'),
          context  => $c->stash('context'),
          term     => $c->stash('term'),
    );
    $term->load(speculative => 1) or return $c->reply->not_found;
    $term->delete or return $c->render_exception($term->error);
    return $c->render(text => 'ok');
}

sub list_context {
    my $c = shift;
    my $lexicon_identifier = $c->stash('lexicon_identifier');
    my $context = $c->stash('context');
    my $terms = Exterms->get_objects(
        query => [ lexicon_identifier => $lexicon_identifier, context => $context ],
        sort_by => 'term',
    );
    $c->respond_to(
       json => sub {
                    my $c = shift;
                    $c->render(json => [ map +{ term => $_->term, gcid => $_->gcid }, @$terms ])
                   },
       yaml  => sub {
                    my $c = shift;
                    $c->render_yaml([ map +{ term => $_->term, gcid => $_->gcid }, @$terms ])
                   },
       html => sub {
                   my $c = shift;
                   $c->res->headers->content_type('text/plain');
                   $c->render(text => join "\n",
                        map sprintf("%40s : %s",$_->term, $_->gcid), @$terms)
                   },
    );
}

1;

