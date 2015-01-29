=head1 NAME

Tuba::Lexicon - Controller for lexcons.

=cut

package Tuba::Lexicon;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use Tuba::Log qw/logger/;

sub show {
    my $c = shift;
    my $lexicon = $c->_this_object or return $c->render_not_found_or_redirect;
    $c->stash(object => $lexicon);
    $c->SUPER::show(@_);
}

sub update_rel_form {
    my $c = shift;
    my $lexicon = $c->_this_object or return $c->render_not_found_or_redirect;
    my $terms;
    if (my $context = $c->param('context')) {
        $terms = $c->orm->{exterm}{mng}->get_objects(query => [lexicon_identifier => $lexicon->identifier, context => $context], sort_by => 'term' );
    } else {
        $terms = [];
    }
    $c->stash(terms => $terms);
    $c->SUPER::update_rel_form(@_);
}

sub update_rel {
    my $c = shift;
    my $lexicon = $c->_this_object or return $c->render_not_found_or_redirect;
    my $term = $c->param('new_term');
    my $gcid = $c->param('new_gcid');
    my $context = $c->param('context');
    my $t = $c->param('delete_term');
    $c->stash(tab => "update_rel_form");
    $c->stash(redirect_params => [ context => $context ]);
    if ($term && $context) {
        my %entry = (
          term    => $term,
          context => $context,
          lexicon_identifier => $lexicon->identifier,
        );
        my $exterm = Exterm->new(%entry);
        $exterm->load(speculative => 1);
        $exterm->gcid($gcid);
        $exterm->save(audit_user => $c->user) or return $c->update_error($exterm->error);
    }
    if (my @delete = @{ $c->every_param('delete_term') }) {
        for my $term (@delete) {
            logger->info("deleting $lexicon $context $term");
            my $ex = Exterm->new(lexicon => $lexicon, term => $term, context => $context);
            $ex->load(speculative => 1) or next;
            $ex->delete or return $c->update_error($ex->error);
        }
    }
    return $c->redirect_without_error('update_rel_form');
}

1;

