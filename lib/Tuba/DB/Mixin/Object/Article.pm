package Tuba::DB::Object::Article;
# Tuba::DB::Mixin::Object::Article;

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
        my $uri = Mojo::URL->new->path("/article/".$s->identifier);
        $uri->base($c->req->url->base) if $c;
        return $uri;
    }
    return $s->SUPER::uri($c,$opts);
}

sub new_from_reference {
    my $class = shift;
    my $ref = shift;
    if (my $doi = $ref->attr('doi')) {
        my $obj = $class->new(doi => $doi);
        $obj->load(speculative => 1) and return $obj;
    }
    return;
}

1;

