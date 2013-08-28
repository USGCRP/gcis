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
        next if $col->type =~ /int/;
        next if $col->type =~ /serial/;
        next if $col->type =~ /boolean/;
        push @query, $col->accessor_method_name => { ilike => '%'.$query_string.'%' };
    }

    return @query;
}

sub dbgrep {
    my $self = shift;
    my %a = @_;

    my $limit = $a{limit} || 10;
    my $query_string = $a{query_string} or return;
    chomp $query_string;
    $query_string =~ s/^\s+//;
    $query_string =~ s/\s+$//;

    my @query = $self->_make_query($query_string) or return;
    my $found = $self->get_objects( query => [ or => \@query ], limit => $limit, );
    return @$found;
}

1;
