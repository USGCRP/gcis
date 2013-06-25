package Tuba::Search;

use Mojo::Base qw/Tuba::Controller/;
use Tuba::Objects qw/-nicknames/;

sub process {
    my $c = shift;
    $c->stash(results => 'foo');
    my $q = $c->param('q') or return $c->render(results => []);

    my $all = $c->table2class;
    my @results;
    for my $table (keys %{ $c->table2class }) {
        my $manager = $c->table2class->{mng};
        push @results, $manager->dbgrep(regex => $q, limit => 10);
    }

    $c->render(results => \@results);
}

