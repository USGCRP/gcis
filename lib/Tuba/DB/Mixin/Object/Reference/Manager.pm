package Tuba::DB::Object::Reference::Manager;
# Tuba::DB::Mixin::Reference::Manager

use strict;
use warnings;

sub _make_query {
    my $s = shift;
    my $str = shift;
    my $dbh = $s->object_class->meta->db->dbh;
    my $q = $dbh->quote('%'.$str.'%');

    my @query;
    # Search Attr:Value, leftovers as title
    if ($str =~ /".*:.*"/){
        my @attr_pairs = split /", */, $str;
        foreach my $attr_pair (@attr_pairs) {
            $attr_pair =~ s/"//g;
            if ( $attr_pair =~ /:/ ) {
                my ($key,$value) = split /:/, $attr_pair;
                push @query, \(qq[attrs->'$key' = '$value' ]);
            }
            else {
                push @query, \(qq[attrs->'Title' ilike '$attr_pair' ]);
            }
        }
    }
    # Search using year and author, identifier, other
    elsif ($str =~ s/(\d{4})//) {
        push @query, ( identifier => { like => $q } );
        my $year = $1;
        $str =~ s/^\s+//g;
        $str =~ s/\s+$//g;
        push @query, \(qq[attrs->'Author' ilike '%$str%' and attrs->'Year' = '$year']);
        push @query, \(qq{array_to_string(avals(attrs),';') ilike $q});
    }
    # Search checking identifier, Author, other
    else {
        push @query, ( identifier => { like => "%$str%" } );
        my $q = $dbh->quote('%'.$str.'%');
        push @query, \(qq[attrs->'Author' ilike $q]);
        push @query, \(qq{array_to_string(avals(attrs),';') ilike $q});
    }
    return @query;
}

1;
