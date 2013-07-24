package Tuba::Search;

use Tuba::DB::Objects qw/-nicknames/;
use Mojo::Base qw/Tuba::Controller/;

sub keyword {
    my $c = shift;
    my $q = $c->param('q') or return $c->render(results => []);

    my $all = $c->orm;
    my @results;
    for my $table (keys %$all) {
        next if $table eq 'publication';
        my $manager = $all->{$table}->{mng};
        next unless $manager->has_urls($c);
        push @results, $manager->dbgrep(query_string => $q, limit => 10);
    }

    $c->render(results => \@results);
}

sub autocomplete {
    my $c = shift;
    my $q = $c->param('q') || $c->json->{q};
    return $c->render(json => []) unless $q && length($q) >= 2;

    my @results;
    for my $type (@{ PublicationTypes->get_objects(all => 1) }) {
        my $table = $type->table;
        my $manager = $c->orm->{$table}{mng} or die "no manager for $table";
        my @got = $manager->dbgrep(query_string => $q, limit => 10);
        for (@got) {
            push @results, sprintf('%10s %s : %s',$table, $_->identifier, $c->elide($_->stringify,80));
        }
    }

    $c->app->log->warn("got : @results");
    return $c->render(json => \@results );
}

1;
