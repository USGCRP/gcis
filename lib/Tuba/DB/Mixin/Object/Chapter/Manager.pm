package Tuba::DB::Object::Chapter::Manager;
# Tuba::DB::Mixin::Chapter::Manager

use strict;
use warnings;

sub dbgrep {
    my $self = shift;
    my %a = @_;

    my $query_string = $a{query_string} or return;
    my $per_page = $a{per_page} || $a{limit} || 10;  #previously implemented as a limit;
    my $user = $a{user};

    my @query = $self->_make_query($query_string);

    my @viewable;
    my @with = ( 'report' );
    if ($user) {
        @viewable = ( or => [ _public => 't', username => $user ] );
        push @with, 'report._report_viewers';
    } else {
        @viewable = ( _public => 't' );
    }

    my $found = $self->get_objects(
        query => [
             or => \@query,
             or => \@viewable
        ],
        with_objects => \@with,
        $a{all} ? () : (page => $a{page}, per_page => $per_page), );

    return @$found;
}

sub _make_query {
    my $s = shift;
    my ($str) = @_;
    my @q = $s->SUPER::_make_query(@_);
    if ($str =~ /chapter (\d+)/i) {
        push @q, number => $1;
    }
    return @q;
}

1;

