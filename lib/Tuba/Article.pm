=head1 NAME

Tuba::Article : Controller class for articles.

=cut

package Tuba::Article;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub list {
    my $c = shift;
    my $objects = Articles->get_objects(sort_by => "identifier");
    my $meta = Article->meta;
    $c->respond_to(
        json => sub { shift->render(json => [ map $_->as_tree, @$objects ]) },
        html => sub { shift->render(template => 'article/objects', meta => $meta, objects => $objects ) }
    );
}

sub show {
    my $c = shift;
    my $meta = Article->meta;
    my $identifier = $c->stash('article_identifier');
    my $object =
      Article->new( identifier => $identifier )->load( speculative => 1)
      or return $c->render_not_found;
    $c->stash(object => $object);
    $c->respond_to(
        json => sub { shift->render(json => $object->as_tree) },
        nt   => sub { shift->render(template => 'object') },
        html => sub { shift->render(template => 'object', meta => $meta, objects => $object ) }
    );
}

sub doi {
    my $c = shift;
    my $doi = $c->stash('doi');
    my $object =
      Article->new( doi => $doi )->load( speculative => 1)
      or return $c->render_not_found;
    $c->redirect_to('show_article' => { article_identifier => $object->identifier } );
}

1;

