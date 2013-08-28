package Tuba::DB::Object::Chapter::Manager;
# Tuba::DB::Mixin::Chapter::Manager

use strict;
use warnings;

sub dbgrep {
    my $self = shift;
    my %a = @_;

    my $query_string = $a{query_string} or return;
    my $limit = $a{limit} || 10;
    my $user = $a{user};

    my @query;
    push @query, ( $_ => { ilike => '%'.$query_string.'%' } ) for qw/identifier title url/;

    my @viewable;
    my @with = ( 'report_obj' );
    if ($user) {
        @viewable = ( or => [ _public => 't', username => $user ] );
        push @with, 'report_obj._report_viewer';
    } else {
        @viewable = ( _public => 't' );
    }

    my $found = $self->get_objects(
        query => [
             or => \@query,
             or => \@viewable
        ],
        with_objects => \@with,
        limit => $limit );

    return @$found;
}

1;

