=head1 NAME

Tuba::Context - Controller for lexicons through /vocabulary.

=cut

package Tuba::Context;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use Tuba::Log qw/logger/;

sub list {
    my $c = shift;
    my $contexts;
    my $all = $c->param('all');
    my @page = $all ? () : (page => $c->page, per_page => $c->per_page);
    my $lexicon_identifier = $c->stash('lexicon_identifier');
    $contexts = Contexts->get_objects(
        query => [ lexicon_identifier => $lexicon_identifier ],
        sort_by => "identifier",
        @page,
    );
    $c->set_pages(Contexts->get_objects_count(
        query => [ lexicon_identifier => $lexicon_identifier ],
    )) unless $all;
    $c->stash(objects => $contexts);
    $c->SUPER::list(@_);
}

sub show {
    my $c = shift;
    my $context = $c->_this_object or do {logger->debug("no _this_object"); return $c->render_not_found_or_redirect;};
    $c->stash(object => $context);
    $c->SUPER::show(@_);
}

sub _this_object {
    my $c = shift;
    #$c->stash(lexicon_identifier => $c->stash('vocabulary_identifier'));
    $c->stash(version_identifier => ''); #we're not supporting versions of vocabularies/contexts
    $c->SUPER::_this_object(@_);
}

1;
