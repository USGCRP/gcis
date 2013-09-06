package Tuba::DB::Object::Finding;
# Tuba::DB::Mixin::Object::Finding;
use strict;

sub numeric {
    my $s = shift;
    if (my $chapter = $s->chapter) {
        return sprintf('%s.%s',$chapter->number // '',$s->ordinal // '');
    }
    return $s->ordinal // '';
}

sub stringify {
    my $c = shift;
    my %args = @_;
    my $val = $args{long} ? $c->statement : $c->identifier;
    if (my $num = $c->numeric) {
        return "$num $val";
    }
    return $val;
}

sub uri {
    my $s = shift;
    my $c = shift;
    my $opts = shift;
    my $tab = $opts->{tab} || 'show';

    return $c->url_for($tab.'_report_finding') if $tab =~ /create/; # create/create_form

    my $route_name = $tab;
    $route_name .= '_report' unless ref $s && $s->chapter_identifier;
    $route_name .= '_finding';

    return $c->url_for($route_name) unless ref $s;

    return $c->url_for(
      $route_name,
      {
        finding_identifier => $s->identifier,
        report_identifier  => $s->report_identifier,
        chapter_identifier => $s->chapter_identifier,
      }
    );
}

1;

