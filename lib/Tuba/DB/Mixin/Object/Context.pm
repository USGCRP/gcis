package Tuba::DB::Object::Context;
use strict;
use Tuba::Log;

sub uri {
    my $s          = shift;
    my $c          = shift;
    my $opts       = shift;
    my $route_name = $opts->{tab} || 'show';
    $route_name .= '_context';
    return $c->url_for($route_name) unless ref($s);
    logger->debug ("context identifier is " . $s->identifier);
    my $url_for; 
    $url_for =  $c->url_for($route_name,  {context_identifier => $s->identifier, 
                                           lexicon_identifier => $s->lexicon_identifier, 
                                           version_identifier => $s->version,
                                          } );
    logger->debug ("url_for returns $url_for");
    #Brute-force construction of uri, since Mojo 7.0 changes broke something
    #This is the only reason uri is overridden here.
    ###TODO It'd be nice to figure out why it broke (known good under 6.24) -RS
    $url_for = $c->url_for("/vocabulary/". $s->lexicon_identifier . "/" . $s->identifier);
    logger->debug ("sending back    $url_for  instead");
    return $url_for;
}

1;
