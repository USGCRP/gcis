package Tuba::DB::Object::Finding;
# Tuba::DB::Mixin::Object::Finding;
use strict;


sub as_tree {
    my $s = shift;
    my $tree = $s->SUPER::as_tree(@_, deflate => 0);
    $tree->{description} = $s->{statement};
    return $tree;
}


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
        return $num if $args{tiny};
        return join ' ', $c->report_identifier.' '.$num if $args{short};
        return sprintf('%s %s %s', $c->report_identifier, $c->meta->table, $num) if $args{long};
        return "$num: $val";
    }
    return $val;
}

sub uri {
    my $s = shift;
    my $c = shift;
    my $opts = shift;
    my $tab = $opts->{tab} || 'show';

    my $chapter_identifier;
    $chapter_identifier = $s->chapter_identifier if ref $s;
    $chapter_identifier ||= $opts->{chapter_identifier};
    $chapter_identifier ||= $c->stash('chapter_identifier');

    my $route_name = $tab;
    $route_name .= '_report' unless $chapter_identifier;
    $route_name .= '_finding';

    return $c->url_for($route_name) unless ref $s;

    return $c->url_for(
      $route_name,
      {
        finding_identifier => $s->identifier,
        report_identifier  => $s->report_identifier,
        chapter_identifier => $chapter_identifier,
      }
    );
}

1;

