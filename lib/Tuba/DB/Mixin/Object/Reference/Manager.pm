package Tuba::DB::Object::Reference::Manager;
# Tuba::DB::Mixin::Reference::Manager

use strict;
use warnings;

#sub dbgrep {
#    my $self = shift;

    # Just search using year and author.

    #my @query = # TODO
    #my $found = $self->get_objects( query => [ or => \@query ], limit => $limit, );
    #return @$found;
#    return ();
#}

sub _make_query {
    my $s = shift;
    my $str = shift;
    return ( identifier => { ilike => '%'.$str.'%' } )
}

1;
