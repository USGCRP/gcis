package Tuba::DB::Object::Term;
use strict;
use Tuba::Log;
use Data::Dumper;

sub stringify {
    my $c = shift;
    return $c->term;
}

sub uri {
    #Duplicating this sub here, to prototype getting uri using a unique key instead of pk
    my $s = shift;
    my $c = shift or die "missing controller for uri";
    my $opts = shift || {};
    my $route_name = $opts->{tab} || 'show';
    $route_name .= '_'.$s->meta->table;
    logger->debug("--- In sub 'Tuba::DB::Object::Term::uri for route_name=$route_name---");
    return $c->url_for($route_name) unless ref $s;
#    logger->debug("still in sub uri");
    my $table = $s->meta->table;
#    logger->debug(Dumper($s));
#    logger->debug(Dumper($s->meta->primary_key_columns));
    $DB::single=1;
    my $unique_key = $s->meta->unique_key_by_name('term_unique');
    my %pk = map {( $_ => $s->$_ )} $unique_key->columns;
    return unless $c->app->routes->find($route_name);
    my %url_params;
    for my $column_name (keys %pk) {
        my $param_name = $column_name;
        $param_name = $table.'_identifier' if $column_name eq 'identifier';
        $param_name = $param_name.'_identifier' if $column_name !~ /identifier/;
        $url_params{$param_name} = $pk{$column_name};
        #also add a param with the unmodified column name, specifically needed for 'term'
        $url_params{$column_name} = $pk{$column_name} unless exists $url_params{$column_name};
    }
    my $url_for = $c->url_for($route_name, \%url_params );
    if ($url_for =~ /show/) {
        logger->warn ("Strange URI created: $url_for\n".
                      "Route name is '$route_name'\n" .
                      "url_params passed to url_for were " . Dumper \%url_params
                     );
    }
    return $url_for;
}



1;
