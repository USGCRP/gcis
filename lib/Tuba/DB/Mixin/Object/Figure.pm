package Tuba::DB::Object::Figure;
# Tuba::DB::Mixin::Object::Figure;
use strict;
use Tuba::Log;

sub numeric {
    my $s = shift;
    if (my $chapter = $s->chapter) {
        return sprintf('%s.%s',$chapter->number // '-',$s->ordinal // '-');
    }
    return $s->ordinal // '-';
}

sub stringify {
    my $c = shift;
    my %args = @_;
    if (my $num = $c->numeric) {
        return $num if $args{tiny};
        return join ' ', $c->report_identifier.' '.$num if $args{short};
        return sprintf('%s %s %s', $c->report_identifier, $c->meta->table, $num) if $args{long};
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
    $s->{_sortkey} = sprintf('%s%s',$chapter_number,$ordinal);
    return $s->{_sortkey};
}

sub get_origination {
    my $s = shift;
    my $origination = $s->{_origination};
    $origination = "{}" if ( ! $origination );
    return $origination;
}

sub set_origination {
    my $s = shift;
    my $new_origination_string = shift;

    $s->{_origination} = $new_origination_string;

    return 1;
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

    my $report_identifier;
    $report_identifier = $s->report_identifier if ref $s; # object method
    $report_identifier //= $c->current_report->identifier;

    my $figure_identifier;
    $figure_identifier = $s->identifier if ref $s;

    return $c->url_for(
      $route_name,
      {
        figure_identifier  => $figure_identifier,
        report_identifier  => $report_identifier,
        chapter_identifier => $chapter_identifier,
      }
    );
}

sub kindred_figures {
    my $s = shift;
    my $results = $s->db->dbh->selectcol_arrayref(<<CUT, {}, $s->identifier);
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
    $tree->{description} = $tree->{caption};
    if (my $chapter_obj = $s->chapter) {
        $tree->{chapter}->{display_name} = $chapter_obj->stringify(display_name => 1, short => 1);
    } else {
        logger->debug($tree->{identifier} . " has no chapter");
        #$tree->{chapter} = {};  #TODO: uncomment to return an empty chapter subtree (it may be useful)
    }
    if (my $report_obj = $s->report) {
        $tree->{report}->{display_name} = $report_obj->stringify(display_name => 1);
    } else {
        logger->warn($tree->{identifier} . " has no report - All figures should be attached to Report!");
    }
    return $tree;
}

1;

