package Tuba::DB::Object::Figure::Manager;
# Tuba::DB::Mixin::Figure::Manager

use strict;
use warnings;

sub dbgrep {
    my $self = shift;
    my %a = @_;

    my $query_string = $a{query_string} or return;
    my $limit = $a{limit} || 10;
    my $user = $a{user};
    my $restrict = $a{restrict};

    my @query = $self->_make_query($query_string);

    my @viewable;
    my @with = ( 'report' );
    if ($user) {
        @viewable = ( or => [ _public => 't', username => $user ] );
        push @with, 'report._report_viewers';
    } else {
        @viewable = ( _public => 't' );
    }

    my @restrict;
    if ($restrict) {
        my ($report) = $restrict =~ /^report_identifier:(.*)$/;
        @restrict = ( and => [ report_identifier => $report ] );
    }

    my $found = $self->get_objects(
        query => [
             or => \@query,
             or => \@viewable,
             @restrict,
        ],
        with_objects => \@with,
        limit => $limit );

    return @$found;
}

1;

