package Tuba::DB::Object::Finding;
# Tuba::DB::Mixin::Object::Finding;
use strict;

sub stringify {
    my $c = shift;
    my %args = @_;
    return $c->statement if $args{long};
    return $c->identifier;
}

sub uri {
    my $s = shift;
    my $c = shift;
    my $opts = shift;
    my $route_name = $opts->{tab} || 'show';

    $route_name .= '_report' unless $s->chapter_identifier;
    $route_name .= '_finding';

    my $got = $c->url_for(
      $route_name,
      {
        finding_identifier => $s->identifier,
        report_identifier  => $s->report_identifier,
        chapter_identifier => $s->chapter_identifier,
      }
    );
    return $got;

}

1;

