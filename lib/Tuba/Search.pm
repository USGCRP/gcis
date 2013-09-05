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

    my @results;
    for my $type (@{ PublicationTypes->get_objects(all => 1) }) {
        my $table = $type->table;
        logger->info('looking in '.$table);
        next if $want && $table ne $want;
        logger->info('still looking in '.$table);
        my $manager = $c->orm->{$table}{mng} or die "no manager for $table";
        my @got = $manager->dbgrep(query_string => $q, limit => $max, user => $c->user);
        for (@got) {
            push @results, join ' ', "[".$table."]",
                                      ( map "{".$_."}", $_->pk_values ),
                                      $c->elide($_->stringify,80);
        }
    }

    return $c->render(json => \@results );
}

sub autocomplete_str_to_object {
    # Reverse the above.
    my $c = shift;
    my $str = shift;
    my @match =
        $str =~ /^
                   \[
                       ( [^]]+ )
                   \]
                   (?:\ \{
                       ( [^}]+ )
                      \}
                   )
                   (?:\ \{
                       ( [^}]+ )
                      \}
                   )?
                   (?:\ \{
                       ( [^}]+ )
                      \}
                   )?
                   (?: [^}]* )$
                  /x;
    my $type = shift @match;
    my @keys = @match;
    return unless $type && @keys;
    my $table = PublicationType->new(identifier => $type)->load->table or die "no table for $type";
    my $class = $c->orm->{$table}->{obj} or die "no class for $table";
    my @pks = $class->meta->primary_key_column_names;
    my %new;
    @new{@pks} = @keys;
    my $obj = $class->new( %new );
    $obj->load(speculative => 1);
    return $obj;
}

1;
