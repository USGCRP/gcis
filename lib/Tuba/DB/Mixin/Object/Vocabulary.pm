package Tuba::DB::Object::Vocabulary;
# Tuba::DB::Mixin::Object::Vocabulary
use strict;
use Data::Dumper;
use Tuba::Log;

# Since Vocabulary is a view, Rose:DB chooses a column at random for the primary key.
# Sometimes it's wrong, so force it to be correct.
logger->debug("Vocabulary primary keys are " . Dumper(__PACKAGE__->meta->primary_key_column_names));
__PACKAGE__->meta->primary_key_columns(['lexicon_identifier']); #primary key column for vocabulary
logger->debug("Vocabulary primary keys are now " . Dumper(__PACKAGE__->meta->primary_key_column_names));

=info This doesn't work right here, it would need to be a pre-init hook for Rose::DB::Object::Loader
=info The relationship getting added _here_ does *not* create the method to access it, so an explicit method is still needed.
__PACKAGE__->meta->add_relationship(contexts => { type   => 'one to many',
                                               class  => 'Tuba::DB::Object::Context',
                                               column_map => {identifier => 'lexicon_identifier'},
                                               methods => [ 'get' ],
                                             }
                                 );
logger->debug("Vocabulary relationships are: " . Dumper(__PACKAGE__->meta->relationships));

no strict 'refs';
my $methods;
for (keys %Tuba::DB::Object::Vocabulary::) {
   $methods= sprintf ("$methods, $_") if defined &{$_};
}
use strict 'refs';
logger->debug("Vocabulary has methods $methods"); 
=cut

sub contexts {
    my $self = shift;
    my $dbs = DBIx::Simple->new($self->db->dbh);
    my @contexts = $dbs->query(<<SQL, $self->lexicon_identifier)->flat;
    select identifier from context c
    where lexicon_identifier = ?
SQL
    return @contexts;
}

1;

