#!/usr/bin/env perl
use Mojo::UserAgent;
use Path::Class qw/file/;
use Data::Dumper;
use feature qw/:all/;
use strict;

my $ua = Mojo::UserAgent->new()->max_redirects(1);

my $which = $ARGV[0] or die "Usage $0 [local|dev|test|prod]\n";
my $dest = {
  local => "http://localhost:3000",
  dev   => "https://data.gcis-dev-front.joss.ucar.edu",
  test  => "https://data.gcis-test-front.joss.ucar.edu",
  prod  => "https://data.globalchange.gov",
  }->{$which};
say "connecting to $dest";
my $which_key = ".gcis_api_key.$which";
my $keyfile = "$ENV{HOME}/".$which_key;
my $key     = file($keyfile)->slurp;
chomp $key;
my %hdrs = ("Accept" => "application/json",
            "Authorization" => "Basic $key");

my $all = $ua->get("$dest/journal.json?all=1")->success->json;

sub handle_all_elsevier {
    my $all = shift;
    for my $journal (@$all) {
        next unless my $url = $journal->{url};
        say $journal->{identifier};
        next unless $url =~ /elsevier/;
        my $this = $ua->get("$dest/journal/$journal->{identifier}.json" => \%hdrs)->res->json;
        if ($this->{files} && @{$this->{files}}) {
            say "have files for $journal->{identifier} already";
            next;
        }
        my $dom = $ua->get($url)->res->dom;
        my $img_url = eval { $dom->find('html > body > div.pgContainer > div.mainCol > div.jnlHeader > div.jnlCover > a > img')->attr('src'); };
        say "skipppng ".$journal->{url} unless $img_url;
        next unless $img_url;
        say $img_url;
        my $tx = $ua->post("$dest/journal/files/$journal->{identifier}" => \%hdrs => form => { file_url => $img_url } );
        my $res = $tx->success or do { warn $tx->error; next; };
        warn "error : ".$res->code.$res->body unless $res->code==200;
        sleep 5;
    }
}

handle_all_elsevier($all);

