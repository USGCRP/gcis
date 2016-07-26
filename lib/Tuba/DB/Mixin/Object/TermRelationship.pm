=head1 NAME

Tuba::DB:Object::TermRelationship : Rose-DB Mixin Object for term subject-predicate-object relationships in term_relationship

=cut


package Tuba::DB::Object::TermRelationship;
use strict;
use Mojo::ByteStream qw/b/;

sub stringify {
    my $c = shift;
    my ($subject, $predicate, $object);
=begin debug1
    no strict 'refs';
    my $methods;
    for (keys %Tuba::DB::Object::TermRel::) {
       $methods= sprintf ("$methods, $_") if defined &{$_};
    }
    use strict 'refs';
#    return "methods are $methods";
=end debug1
=cut

    $subject = $c->term_obj;
    $predicate = $c->relationship;
    $object = $c->term;
    return b(sprintf('<a href=/term/%s>%s</a> <i><a href=/relationship/%s>%s</a></i> <a href=/term/%s>%s</a>', 
                       $subject->identifier, $subject->stringify, 
                       $predicate->stringify, $predicate->stringify, 
                       $object->identifier, $object->stringify));
=begin comment
    return b(sprintf("
\$c is a %s  <br> 
\$subject is a %s <br> 
\$predicate is a %s <br> 
\$object is a %s <br>
term is a %s <br>
term = %s <br>
term_subject is a %s <br>
term_obj is a %s <br>
term_obj = %s <br>
term_object is a %s <br>
" . #relationship_obj is a %s <br>
"methods are %s
", 
ref($c), 
ref($subject), 
ref($predicate)||'<b>string</b>: '.$predicate, 
ref($object),
ref($c->term),
$c->term->stringify,
ref($c->term_subject)||'<b>string</b>: '.$c->term_subject,
ref($c->term_obj),
$c->term_obj->stringify,
ref($c->term_object)||'<b>string</b>: '.$c->term_object,
#ref($c->relationship_obj),
$methods
));
=end comment
=cut
}
1;
