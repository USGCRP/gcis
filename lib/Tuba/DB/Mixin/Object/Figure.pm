package Tuba::DB::Object::Figure;
# Tuba::DB::Mixin::Object::Figure;
use strict;

sub numeric {
    my $c = shift;
    my $chapter = $c->chapter or return "";
    return $c->ordinal unless defined($chapter->number);
    return join '.', $chapter->number, $c->ordinal // '';
}

sub stringify {
    my $c = shift;
    my %args = @_;
    if (my $num = $c->numeric) {
        return $num if $args{tiny};
        return join ': ', $num, ($c->title || $c->identifier);
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

    my $chapter_identifier;
    $chapter_identifier = $s->chapter_identifier if ref $s;
    $chapter_identifier ||= $opts->{chapter_identifier};
    $chapter_identifier ||= $c->stash('chapter_identifier');

    my $route_name = $tab;
    $route_name .= '_report' unless $chapter_identifier;
    $route_name .= '_figure';

    return $c->url_for($route_name) unless ref $s;

    return $c->url_for(
      $route_name,
      {
        figure_identifier  => $s->identifier,
        report_identifier  => $s->report_identifier,
        chapter_identifier => $chapter_identifier,
      }
    );
}

sub kindred_figures {
    my $s = shift;
    my $results = $s->db->dbh->selectrow_arrayref(<<CUT, {}, $s->identifier);
select distinct(y.figure_identifier,y.report_identifier)
from image_figure_map x
inner join image_figure_map y
on x.image_identifier = y.image_identifier and (x.figure_identifier != y.figure_identifier or x.report_identifier != y.report_identifier)
where x.figure_identifier=?
CUT
    my @objs;
    for my $row (@$results) {
        $row =~ s/^\(//;
        $row =~ s/\)$//;
        my ($figure,$report) = split /,/, $row;
        my $obj = Tuba::DB::Object::Figure->new(identifier => $figure, report_identifier => $report);
        $obj->load(speculative => 1);
        push @objs, $obj;
    }
    return @objs;
}

sub as_tree {
    my $s = shift;
    my %a = @_;
    my $c = $a{c};
    my $tree = $s->SUPER::as_tree(@_);
    $tree->{kindred_figures} = [ map $_->uri($c), $s->kindred_figures ] unless $a{bonsai};
    return $tree;
}

1;

