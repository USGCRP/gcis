package Tuba::DB::Object::Generic::Manager;
# Tuba::DB::Mixin::Generic::Manager

use strict;
use warnings;

sub _make_query {
    my $s = shift;
    my $str = shift;
    my $dbh = $s->object_class->meta->db->dbh;
    my @query  = ( identifier => { like => "%$str%" } );

    # Search using attribuets .
    my $q = $dbh->quote('%'.$str.'%');
    push @query, \(qq[array_to_string(avals(attrs),' ') ilike $q]);
    return @query;
}

1;
