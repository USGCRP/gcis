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

    my @query = $self->_make_query($query_string);

    my @viewable;
    my @with;
    if ($user) {
        @viewable = ( or => [ _public => 't', username => $user ] );
        @with = ( with_objects => '_report_viewers' );
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

sub indicator_publication_years {
    my $self = shift;
    my %a = @_;

    my $user = $a{user};

    my %query;
    my $found= $self->get_objects(
        select => [ 'publication_year' ],
        query => [
            report_type_identifier => 'indicator',
            _public => 't',
        ],
        distinct => 1,
    );

    my $years;
    foreach my $object ( @$found ) {
        push @$years, $object->publication_year;
    }

    return $years;
}

1;

