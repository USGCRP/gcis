package Tuba::DB::Object::Journal;
# Tuba::DB::Mixin::Object::Journal;

sub stringify {
    my $s = shift;
    return $s->title if $s->title;
    return $s->identifier;
}

sub uri {
    my $s = shift;
    my $c = shift;
    my $opts = shift || {};
    my $route_name = $opts->{tab} || 'show';
    if ($route_name eq 'show') {
        my $uri = Mojo::URL->new->path("/journal/".$s->identifier);
        $uri->base($c->req->url->base) if $c;
        return $uri;
    }
    return $s->SUPER::uri($c,$opts);
}

1;

