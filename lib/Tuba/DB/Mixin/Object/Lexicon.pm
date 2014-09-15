package Tuba::DB::Object::Lexicon;
# Tuba::DB::Mixin::Object::Lexicon
use strict;

sub contexts {
    my $s = shift;
    my $dbs = DBIx::Simple->new($s->db->dbh);
    my @contexts = $dbs->query(<<SQL, $s->identifier)->flat;
    select distinct(context) from lexicon l
    inner join exterm e on e.lexicon_identifier = l.identifier
    where lexicon_identifier = ?
SQL
    return @contexts;
}

1;

