package Tuba::DB::Object::Table;
# Tuba::DB::Mixin::Object::Table;
use strict;

sub numeric {
    my $c = shift;
    my $chapter = $c->chapter or return "";
    return $c->ordinal unless defined($chapter->number);
    return join '.', $chapter->number, $c->ordinal // '';
}

sub stringify {
    my $c = shift;
    if (my $num = $c->numeric) {
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
    $route_name .= '_table';

    return $c->url_for($route_name) unless ref $s;

    return $c->url_for(
      $route_name,
      {
        table_identifier => $s->identifier,
        report_identifier  => $s->report_identifier,
        chapter_identifier => $chapter_identifier,
      }
    );
}

sub kindred_tables {
    my $s = shift;
    my $results = $s->db->dbh->selectrow_arrayref(<<CUT, {}, $s->identifier);
select distinct(y.table_identifier,y.report_identifier)
from image_table_map x
inner join image_table_map y
on x.image_identifier = y.image_identifier and (x.table_identifier != y.table_identifier or x.report_identifier != y.report_identifier)
where x.table_identifier=?
CUT
    my @objs;
    for my $row (@$results) {
        $row =~ s/^\(//;
        $row =~ s/\)$//;
        my ($table,$report) = split /,/, $row;
        my $obj = Tuba::DB::Object::Table->new(identifier => $table, report_identifier => $report);
        push @objs, $obj;
    }
    return @objs;
}

1;

