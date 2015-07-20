package Tuba::DB::Object::Reference::Manager;
# Tuba::DB::Mixin::Reference::Manager

use strict;
use warnings;

sub _make_query {
    my $s = shift;
    my $str = shift;
    my $dbh = $s->object_class->meta->db->dbh;
    my @query  = ( identifier => { like => "%$str%" } );
    my $q = $dbh->quote('%'.$str.'%');

    # Search using year and author.
    if ($str =~ s/(\d{4})//) {
        my $year = $1;
        $str =~ s/^\s+//g;
        $str =~ s/\s+$//g;
        push @query, \(qq[attrs->'Author' ilike $q and attrs->'Year' = '$year']);
    } else {
        my $q = $dbh->quote('%'.$str.'%');
        push @query, \(qq[attrs->'Author' ilike $q]);
    }
    push @query, \(qq{array_to_string(avals(attrs),';') ilike $q});
    return @query;
}

1;
