package Tuba::DB::Object::Finding;
# Tuba::DB::Mixin::Object::Finding;

sub stringify {
    my $c = shift;
    my %args = @_;
    return $c->statement if $args{long};
    return $c->identifier;
}

sub uri {
    my $s = shift;
    my $c = shift;
    return $c->url_for( 'show_finding', { 'finding_identifier' => $s->identifier, report_identifier => $s->report } );
}

1;

