package Tuba::Search;

use Tuba::DB::Objects qw/-nicknames/;
use Mojo::Base qw/Tuba::Controller/;
use List::MoreUtils qw/mesh/;
use Tuba::Log;
use strict;

=head2 keyword

The engine for /search.

There are 2 basic modes of operation:
=item Returning actual results
=item Getting a count (by type) of all objects matched by search term

=cut

sub keyword {
    my $c = shift;
    my $q = $c->param('q') or return $c->render(results => [], result_count_text => 'Please enter search terms');

    my $orm = $c->orm;
    my @tables = keys %$orm;
    my $types = $c->every_param('type');  #array ref to multiple values
    @tables = @$types unless !@$types or grep {$_ eq 'all'} @$types;
    my $per_page = $c->param('per_page') || (@tables > 1 ? 10 : 50); # default to 10 per type if multiple types
    my $all = $c->param('all') ? 1 : 0;
    my $count_only = $c->param('count_only') ? 1 : 0;  #to only return count of each type
    my $featured_only = $c->param('featured_only') ? 1 : 0; #only return featured publications
    my $bonsai = ($c->param('format') // '') eq 'detailed' ? 0 : 1; #default to bonsai=1 unless &format=detailed
    my @results;
    my $result_count_text;
    my $hit_max = 0;
    for my $table (@tables) {
        next if $table eq 'publication';
        next if $featured_only and $table ne 'report';  #ugly hack, only reports are currently featured
        my $manager = $orm->{$table}->{mng};
        next unless $manager->has_urls($c);
        my @these = $manager->dbgrep(query_string => $q, user => $c->user, all  => $all, page => $c->page, per_page => $per_page, count_only => $count_only, featured_only => $featured_only);
        $hit_max = 1 if @these==$per_page && @tables > 1;
        push @results, @these;
    }

    $result_count_text = scalar @results;
    if (@tables == 1 && $result_count_text == $per_page) {
        $result_count_text = "more than $per_page results.  Only showing $per_page in this page.";
        $result_count_text .= " (Page ".$c->page.")" if $c->page > 1;
    } else {
        $result_count_text = "$result_count_text result";
        $result_count_text .= 's' unless @results==1;
        if (!$hit_max or $all) {
            $result_count_text .= '.';
        } else {
            $result_count_text .= " on this page. (Only up to $per_page results of each type are shown). ".
                "To see more, chose a type in the form above."; 
        }
    }
    $c->stash(result_count_text => $result_count_text);
    $c->respond_to(
        any => sub { shift->render(results => \@results); },
        json => sub { my $c = shift; $c->render(json => [ map $_->as_tree(c => $c, bonsai => $bonsai), @results ]); },
        yaml => sub { my $c = shift; $c->render_yaml([ map $_->as_tree(c => $c, bonsai => $bonsai), @results ]); },
    );
}

=head2 autocomplete

Returns items (in JSON) matching a partial word.

This is particulairly used by templates/controls/autocomplete.html.ep to provide 
interactive search capabilities while viewing a resource.

If a new table and resource is added, the table name must be inserted at the lable 
searchable_tables.

=cut

sub autocomplete {
    my $c = shift;
    my $q = $c->param('q') || $c->json->{q};
    return $c->render(json => []) unless $q && length($q) >= 1;
    my $max = $c->param('items') || 20;
    my $want = $c->param('type') || 'all';  # all == all publications, full = orgs, people too
    my $elide = $c->param('elide') || 80;
    my $gcids = $c->param('gcids');
    my $restrict = $c->param('restrict');

    my @tables;
    searchable_tables: #allow only specified tables to be searched
    if ($want && $want=~/^(array|finding|table|journal|region|gcmd_keyword|person|organization|reference|file|activity|dataset|figure|image|report|chapter|article|webpage|book|generic|platform|instrument|term)$/) {
       @tables = ( $want );
    } elsif ($want && ($want !~ /^(all|full)$/)) {
        return $c->render(json => { error => "undefined type" } );
    } elsif ($want eq 'all') {
       @tables = map $_->table, @{ PublicationTypes->get_objects(all => 1) };
    } elsif ($want eq 'full') {
       @tables = map $_->table, @{ PublicationTypes->get_objects(all => 1) };
       push @tables, ('organization', 'person');
    }
    my @results;
    for my $table (@tables) {
        next if $want && $want !~ /^(all|full)$/ && $table ne $want;
        my $manager = $c->orm->{$table}{mng} or die "no manager for $table";
        my @got = $manager->dbgrep(query_string => $q, limit => $max, user => $c->user, restrict => $restrict);
        for (@got) {
            if ($gcids) {
                push @results, $_->as_gcid_str($c,$elide,$table);
            } else {
                push @results, $_->as_autocomplete_str($elide,$table);
            }
        }
    }

    return $c->render(json => \@results );
}

sub autocomplete_str_to_object {
    # Reverse the above.
    my $c = shift;
    my $str = shift;
    my ($type) =
        $str =~ /^ \[
                       ( [^]]+ )
                   \]
                  /x;
    return unless $type;
    my $class = $c->orm->{$type}->{obj} or die "no class for $type";
    return $class->new_from_autocomplete($str);
}

sub gcid {
    my $c = shift;
    $c->render(template => "search/gcid");
}


1;
