package Tuba::DB::Object::Table::Manager;
# Tuba::DB::Mixin::Table::Manager

use strict;
use warnings;

sub dbgrep {
    my $self = shift;
    my %a = @_;

    my $query_string = $a{query_string} or return;
    my $per_page = $a{per_page} || $a{limit} || 10;  #previously implemented as a limit;
    my $user = $a{user};

    my @query = $self->_make_query($query_string);
    my $dbh = $self->object_class->meta->db->dbh;
    my $q = $dbh->quote('%'.$query_string.'%');
    push @query, \(qq[t2.number::text || '.' || ordinal::text like $q]);

    my @viewable;
    my @with = ( 'chapter', 'report' );
    if ($user) {
        @viewable = ( or => [ _public => 't', username => $user ] );
        push @with, 'report._report_viewers';
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
            with_objects => \@with, );
        #bless the hash, so that rendering works (mostly) the same as full-fledged results
        my @count = $count ? (bless { results_count => $count } , $self->object_class ) : ();
        $found = \@count;
    } else {
        $found = $self->get_objects(
            query => [
                 or => \@query,
                 or => \@viewable
            ],
            with_objects => \@with,
            $a{all} ? () : (page => $a{page}, per_page => $per_page), );
    }
    return @$found;
}

1;

