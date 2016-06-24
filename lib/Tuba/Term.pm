=head1 NAME

Tuba::Term : Controller class for terms.

=cut

package Tuba::Term;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub show {
    my $c = shift;
    my $identifier = $c->stash('term_identifier');
    my $object = Term->new (identifier => $identifier )
      -> load( speculative => 1 ) or return $c->reply->not_found;
    $c->stash( object => $object );
    $c->SUPER::show(@_);
}

# Overriding to add relationships in json and yaml requests
sub make_tree_for_show {
    my $c = shift;
    my $term = shift;
    #create the default tree
    my $tree = $c->SUPER::make_tree_for_show($term);
    #for children, this term is the subject; for parents, it is the object of the relationship
    my $children = TermRelationships->get_objects( query => [term_subject => $term->identifier] );
    my $parents = TermRelationships->get_objects( query => [term_object => $term->identifier] );
    my $term_maps = TermMaps->get_objects( query => [term_identifier => $term->identifier] );
    #add them to the tree
    $tree->{children} = [ map +{ relationship => $_->relationship_identifier,
                                 #this should work, but gets "cant locate method uri"
                                 #object => $_->term_object->uri($c) }, @$children ];
                                 object => "/term/" . $_->term_object }, @$children ];
    $tree->{parents} = [ map +{ subject => "/term/" . $_->term_subject ,
                                relationship => $_->relationship_identifier }, @$parents ];
    $tree->{term_maps} = [ map +{ relationship => $_->relationship_identifier , 
                                  object => $_->gcid } , @$term_maps ];
    return $tree;
}

1;
