#!/usr/bin/env perl

use Mojo::UserAgent;
use Data::Dumper;
use strict;

$| = 1;

my $line = <STDIN>;
$line =~ s/\r//;
chomp($line);
my $report = $line;
print "report $report\n";

my @ids = ();
my @titles = ();

foreach $line (<STDIN>) {
    $line =~ s/\r//;
    chomp($line);
    # print "line $line\n";
    my ($title, $id) = split(/\t/, $line);
    # print "id $id  title $title\n";
    push @ids, $id;
    push @titles, $title;
}
my $n = @ids;
print "checking $n figures\n";
my @is_found = (0) x $n;

my %index_id = map {$ids[$_] => $_} 0..$#ids;
# print Dumper %index_id;

my $base = "http://data-stage.globalchange.gov";
my $param = "?all=1";
my $url = "$base/report/$report/figure.json$param";
# print "url $url\n";

my $ua = Mojo::UserAgent->new;
my $figures = $ua->get($url)->res->json;
# print Dumper $figures;

my $n_gcis = 0;

for my $figure (@$figures) {
    $n_gcis++;

    my $id = $figure->{identifier};
    my $title = $figure->{title};
    
    if(exists($index_id{$id})) {
        print "  gcis id not found in file: $id\n";
        next;
    }

    my $index = $index_id{$id};
    $is_found[$index] = 1;

    if($titles[$index] != $title) {
        print "  titles do not match for id $id\n";
        print "    file: $titles[$index]\n";
        print "    gcis: $title\n";
    }
}

if ($n != $n_gcis) {
    print "  number of figures do not match\n";
    print "    file: $n\n";
    print "    gcis: $n_gcis\n";
}

foreach my $index (0..$#ids) {
    if (!$is_found[$index]) {
        print "  file id not found in gics: $ids[$index]\n";
    }
}

print "done\n";
