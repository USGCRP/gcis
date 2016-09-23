=head1 NAME

Tuba::DB::Object::Manager : base class for manager classes

=cut

package Tuba::DB::Object::Manager;
use base 'Rose::DB::Object::Manager';

use strict;
use warnings;

sub has_urls {
    my $s = shift;
    my $c = shift;
    my $table = $s->object_class->meta->table;
    my $route_name = 'show_'.$table;
    return unless $c->app->routes->find($route_name);

}

sub _make_query {
    my $s = shift;
    my $query_string = shift;
    my @query;

    for my $col ($s->object_class->meta->columns) {
        next if $col->type =~ /time/;
        next if $col->type =~ /numeric/;
        next if $col->type =~ /serial/;
        next if $col->type =~ /boolean/;
        next if $col->type =~ /hstore/;
        next if $col->type =~ /date/;
        my $name = $col->accessor_method_name;
        if ($col->type =~ /array/) {
            my $q = $s->object_class->meta->db->dbh->quote('%'.$query_string.'%');
            push @query, \(qq[array_to_string($name,',') ilike $q]);
            next;
        } elsif ($col->type =~ /int/) {
            my $q = $s->object_class->meta->db->dbh->quote('%'.$query_string.'%');
            push @query, \(qq[$name\::text like $q]);
            next;
        } elsif ($col->type =~ /is[sb]n/) {
            my $q = $s->object_class->meta->db->dbh->quote('%'.$query_string.'%');
            push @query, \(qq[$name\::text like $q]);
            next;
        };

        push @query, $name => { ilike => '%'.$query_string.'%' };
    }

    return @query;
}

sub dbgrep {
    my $self = shift;
    my %a = @_;

    my $per_page = $a{per_page} || $a{limit} || 10;  #previously implemented as a limit;
    my $query_string = $a{query_string} or return;
    chomp $query_string;
    $query_string =~ s/^\s+//;
    $query_string =~ s/\s+$//;

    my @query = $self->_make_query($query_string) or return;
    my $found;
    if ($a{count_only}) {
        my $count = $self->get_objects_count( query => [ or => \@query ]);
        #bless the hash, so that rendering works (mostly) the same as full-fledged results
        my @count = $count ? (bless { results_count => $count } , $self->object_class ) : (); 
        $found = \@count;
    } else {
        $found = $self->get_objects( query => [ or => \@query ],
                                     $a{all} ? () : (page => $a{page}, per_page => $per_page),
                                     #debug => 1,  #dump raw SQL to stderr (in morbo output, not devel log)
                                   );
    } 
    return @$found;
}



1;
