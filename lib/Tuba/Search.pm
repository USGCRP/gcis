package Tuba::Search;

use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;

sub process {
    my $c = shift;
    my $q = $c->param('q') or return $c->render(results => []);

    my $all = Tuba::DB::Objects->table2class;
    my @results;
    for my $table (keys %$all) {
        next if $table eq 'publication';
        my $manager = $all->{$table}->{mng};
        next unless $manager->has_urls($c);
        push @results, $manager->dbgrep(query_string => $q, limit => 10);
    }

    $c->render(results => \@results);
}

1;

