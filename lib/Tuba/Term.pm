=head1 NAME

Tuba::Term : Controller class for terms.

=cut

package Tuba::Term;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use Tuba::Log;

sub list {
    my $c = shift;
    my $all = $c->param('all') ? 1 : 0;
    #only /vocabulary sets this, for /term skip this and just list all terms
    if (my $vocabulary_identifier = $c->stash('lexicon_identifier')) {
        my $context_identifier = $c->stash('context_identifier');
        my $objects = Terms->get_objects(query => [lexicon_identifier => $vocabulary_identifier,
                                                   context_identifier => $context_identifier,
                                                      ],
                                         sort_by => $c->_default_list_order,
                                         $all ? () : (page => $c->page, per_page => $c->per_page)
                                        );
        $c->stash(objects=>$objects);
        $c->set_pages(Terms->get_objects_count(query => [lexicon_identifier => $vocabulary_identifier,
                                                         context_identifier => $context_identifier,
                                                        ],
                                              )) unless $all;
    }
    $c->SUPER::list(@_);
}


sub show {
    my $c = shift;
    my $object = Term->new ( lexicon_identifier => $c->stash('lexicon_identifier'),
                             context_identifier => $c->stash('context_identifier'),
                             term               => $c->stash('term'),
                           ) -> load( use_key => 'term_unique',
                                      speculative => 1 );
    if (!$object) {
        my $identifier = $c->stash('term_identifier');
        $object = Term->new (identifier => $identifier )
          -> load( speculative => 1 );
    }
    if (!$object) {
        my $stashlist;
        foreach (sort(keys %{$c->stash})) { $stashlist .= "\n  $_ => " . $c->stash($_) }
        logger->debug(" Available keys are: $stashlist");
        return $c->reply->not_found;
    }
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
    my $children = TermRelationships->get_objects( query => [term_subject => $term->identifier], with_objects => 'term' );
    my $parents = TermRelationships->get_objects( query => [term_object => $term->identifier], with_objects => 'term_obj' );
    my $term_maps = TermMaps->get_objects( query => [term_identifier => $term->identifier] );
    #add them to the tree
    $tree->{children} = [ map +{ relationship => $_->relationship_identifier,
                                 #the following gets "cant locate method uri", because a Tuba::DB::Object (term) needs to be passed, not just the column value (term_object)
                                 #object => $_->term_object->uri($c) }, @$children ];  #<-- doesn't work
                                 object => $_->term->uri($c) }, @$children ];
                                 object_tree => $_->term_object ? $c->make_tree_for_show($_->term) : '',
                                                                                        # Term->new (identifier => $_->term_object)-> load(speculative=>1) ) : '',
                                 #the above is an alternative to $_->term, esp. useful if get_objects for $children doesn't include with_objects
    $tree->{parents} = [ map +{ subject => $_->term_obj->uri($c) ,
                                relationship => $_->relationship_identifier }, @$parents ];
    $tree->{term_maps} = [ map +{ relationship => $_->relationship_identifier , 
                                  object => $_->gcid } , @$term_maps ];
    return $tree;
}

1;
