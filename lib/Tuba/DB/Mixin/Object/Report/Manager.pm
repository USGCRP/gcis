package Tuba::DB::Object::Report::Manager;
# Tuba::DB::Mixin::Report::Manager

use strict;
use warnings;

sub dbgrep {
    my $self = shift;
    my %a = @_;

    my $query_string = $a{query_string} or return;
    my $limit = $a{limit} || 10;
    my $user = $a{user};

    my @query;
    push @query, ( $_ => { ilike => '%'.$query_string.'%' } ) for qw/identifier title organization url doi/;

    my @viewable;
    my @with;
    if ($user) {
        @viewable = ( or => [ _public => 't', username => $user ] );
        @with = ( with_objects => '_report_viewer' );
    } else {
        @viewable = ( _public => 't' );
    }

    my $found= $self->get_objects(
        query => [
             or => \@query,
             or => \@viewable
        ],
        @with,
        limit => $limit );

    return @$found;
}

1;

