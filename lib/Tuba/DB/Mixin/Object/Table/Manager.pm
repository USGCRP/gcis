package Tuba::DB::Object::Table::Manager;
# Tuba::DB::Mixin::Table::Manager

use strict;
use warnings;

sub dbgrep {
    my $self = shift;
    my %a = @_;

    my $query_string = $a{query_string} or return;
    my $limit = $a{limit} || 10;
    my $user = $a{user};

    my @query = $self->_make_query($query_string);

    my @viewable;
    my @with = ( 'report' );
    if ($user) {
        @viewable = ( or => [ _public => 't', username => $user ] );
        push @with, 'report._report_viewer';
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

