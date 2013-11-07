package Tuba::Search;

use Tuba::DB::Objects qw/-nicknames/;
use Mojo::Base qw/Tuba::Controller/;
use List::MoreUtils qw/mesh/;
use Tuba::Log;
use strict;

sub keyword {
    my $c = shift;
    my $q = $c->param('q') or return $c->render(results => []);

    my $all = $c->orm;
    my @results;
    for my $table (keys %$all) {
        next if $table eq 'publication';
        my $manager = $all->{$table}->{mng};
        next unless $manager->has_urls($c);
        push @results, $manager->dbgrep(query_string => $q, user => $c->user, limit => 10);
    }

    $c->render(results => \@results);
}

sub autocomplete {
    my $c = shift;
    my $q = $c->param('q') || $c->json->{q};
    return $c->render(json => []) unless $q && length($q) >= 1;
    my $max = $c->param('items') || 20;
    my $want = $c->param('type');
    my $elide = $c->param('elide') || 80;

    my @tables;
    if ($want && $want=~/^(keyword|person|organization|reference)$/) {
       @tables = ( $want );
    } else {
       @tables = map $_->table, @{ PublicationTypes->get_objects(all => 1) };
    }
    my @results;
    for my $table (@tables) {
        next if $want && $want ne 'all' && $table ne $want;
        logger->info('looking in '.$table);
        my $manager = $c->orm->{$table}{mng} or die "no manager for $table";
        my @got = $manager->dbgrep(query_string => $q, limit => $max, user => $c->user);
        for (@got) {
            push @results, join ' ', "[".$table."]",
                                      ( map "{".$_."}", $_->pk_values ),
                                      $c->elide($_->stringify,$elide);
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
    my $table = PublicationType->new(identifier => $type)->load->table or die "no table for $type";
    my $class = $c->orm->{$table}->{obj} or die "no class for $table";
    return $class->new_from_autocomplete($str);
}

1;
