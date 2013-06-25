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
    my $route_name = 'show_'.$s->object_class->meta->table;
    return unless $c->app->routes->find($route_name);

}

sub dbgrep {
    my $self = shift;
    my %a = @_;
    my $query_string = $a{query_string} or return;
    chomp $query_string;
    $query_string =~ s/^\s+//;
    $query_string =~ s/\s+$//;
    my $limit = $a{limit} || 10;
    my @query;
    for my $col ($self->object_class->meta->columns) {
        next if $col->type =~ /time/;
        next if $col->type =~ /numeric/;
        next if $col->type =~ /int/;
        next if $col->type =~ /serial/;
        push @query, $col->accessor_method_name => { ilike => '%'.$query_string.'%' };
    }
    return [] unless @query;
    my $found = $self->get_objects( query => [ or => \@query ], limit => $limit, );
    use Data::Dumper;
    warn "$self tried : ".Dumper(\@query);
    return @$found;
}

1;
