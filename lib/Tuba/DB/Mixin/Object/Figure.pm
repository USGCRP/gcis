package Tuba::DB::Object::Figure;
# Tuba::DB::Mixin::Object::Figure;
use strict;

sub numeric {
    my $c = shift;
    my $chapter = $c->chapter or return "";
    return join '.', $chapter->number, $c->ordinal;
}

sub stringify {
    my $c = shift;
    if (my $num = $c->numeric) {
        return join ' ', $num, ($c->title || $c->identifier);
    }
    return $c->title || $c->identifier;
}

sub sortkey {
    my $s = shift;
    return $s->{_sortkey} if defined($s->{_sortkey});
    my $chapter_number = 0;
    if (my $chapter = $s->chapter) {
        $chapter_number = $chapter->number || 0;
    }
    my $ordinal = $s->ordinal || 0;
    $s->{_sortkey} = sprintf('%10d%10d',$chapter_number,$ordinal);
    return $s->{_sortkey};
}

sub uri {
    my $s = shift;
    my $c = shift;
    my $opts = shift;
    my $tab = $opts->{tab} || 'show';

    return $c->url_for($tab.'_report_figure') if $tab =~ /create/; # create/create_form

    my $route_name = $tab;
    $route_name .= '_report' unless ref $s && $s->chapter_identifier;
    $route_name .= '_figure';

    return $c->url_for($route_name) unless ref $s;

    return $c->url_for(
      $route_name,
      {
        figure_identifier  => $s->identifier,
        report_identifier  => $s->report_identifier,
        chapter_identifier => $s->chapter_identifier,
      }
    );
}

1;

