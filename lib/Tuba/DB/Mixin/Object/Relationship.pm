package Tuba::DB::Object::Relationship;
use strict;
use Tuba::Log;

sub stringify {
    my $c = shift;
    return $c->identifier;
}

sub uri {
    my $s          = shift;
    my $c          = shift;
    my $opts       = shift;
    my $route_name = $opts->{tab} || 'show';
    $route_name .= '_relationship';
    return $c->url_for($route_name) unless ref($s);
    logger->debug ("relationship identifier is " . $s->identifier);
    my $url_for; 
    $url_for =  $c->url_for($route_name,  relationship_identifier => $s->identifier  );
    logger->debug ("url_for returns $url_for");
    #Brute-force construction of uri, since Mojo 7.0 changes broke something
    ###TODO It'd be nice to figure out why it broke (known good under 6.24) -RS
    $url_for = $c->url_for("/relationship/". $s->identifier);
    logger->debug ("sending back    $url_for  instead");
    return $url_for;
}

1;
