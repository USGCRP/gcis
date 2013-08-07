=head1 NAME

Tuba::Article : Controller class for articles.

=cut

package Tuba::Article;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $meta = Article->meta;
    my $identifier = $c->stash('article_identifier');
    my $object =
      Article->new( identifier => $identifier )->load( speculative => 1)
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->SUPER::show(@_);
}

sub doi {
    my $c = shift;
    my $doi = $c->stash('doi');
    my $object =
      Article->new( doi => $doi )->load( speculative => 1)
      or return $c->render_not_found;
    $c->redirect_to('show_article' => { article_identifier => $object->identifier } );
}

sub _journal_list {
    my @journals = @{ Journals->get_objects(sort_by => 'identifier') };
    return [ '', map [ sprintf( '%s : %.80s', ( $_->identifier || '' ), $_->title ), $_->identifier ], @journals ];
}

sub update_form {
    my $c = shift;
    $c->stash(
        controls => {
            journal => sub {
                my $c   = shift;
                my $obj = shift;
                +{
                    template => 'select',
                    params   => { values => $c->_journal_list }
                };
              }
        }
    );
    $c->SUPER::update_form(@_);
}

1;

