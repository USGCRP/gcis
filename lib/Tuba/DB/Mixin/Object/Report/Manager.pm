package Tuba::DB::Object::Report::Manager;
# Tuba::DB::Mixin::Report::Manager

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
    my @with;
    if ($user) {
        @viewable = ( or => [ _public => 't', username => $user ] );
        @with = ( with_objects => '_report_viewers' );
    } else {
        @viewable = ( _public => 't' );
    }

    my $found;
    if ($a{count_only}) {
        my $count = $self->get_objects_count(
            query => [
                 or => \@query,
                 or => \@viewable
            ],
            @with, );
        #bless the hash, so that rendering works (mostly) the same as full-fledged results
        my @count = $count ? (bless { results_count => $count } , $self->object_class ) : ();
        $found = \@count;
    } else {
       $found = $self->get_objects(
            query => [
                 or => \@query,
                 or => \@viewable
            ],
            @with,
            $a{all} ? () : (page => $a{page}, per_page => $per_page), );
    } 
    return @$found;
}

1;

