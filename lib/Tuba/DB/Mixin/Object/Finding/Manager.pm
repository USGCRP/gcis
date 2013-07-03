package Tuba::DB::Object::Finding::Manager;
# Tuba::DB::Mixin::Finding::Manager

use strict;
use warnings;

sub dbgrep {
    my $self = shift;
    my %a = @_;

    my $query_string = $a{query_string} or return;
    my $limit = $a{limit} || 10;

    my @found = $self->SUPER::dbgrep(%a);

    # Also find findings with keywords that match.
    my @query;
    for my $col (Tuba::DB::Object::Keyword->meta->columns) {
        next unless $col->type =~ /char/i;
        push @query, $col->accessor_method_name => { ilike => '%'.$query_string.'%' };
    }
    my $new = Tuba::DB::Object::Keyword::Manager->get_objects( query => [ or => \@query ], require_objects => [qw/finding_objs/], limit => $limit );
    my %seen = map { $_->identifier => 1 } @found;
    for (@$new) {
        for ($_->finding_objs) {
            push @found, $_ unless $seen{$_->identifier}++;
        }
    }
    return @found;
}

1;

