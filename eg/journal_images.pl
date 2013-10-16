#!/usr/bin/env perl
use Mojo::UserAgent;
use Path::Class qw/file/;
use Data::Dumper;
use feature qw/:all/;
use strict;

package Parser;

sub elsevier {
    my $class = shift;
    my $dom = shift;
    my $found = eval { $dom->find('html > body > div.pgContainer > div.mainCol > div.jnlHeader > div.jnlCover > a > img')->attr('src'); };
    return if $@;
    return $found;
}

sub wiley   {
    my $class = shift;
    my $dom = shift;
    my $found = eval {
        $dom->find('html > body > div.page-wrap > div#leftBorder > div#rightBorder.bordered > div#content > div#mainContent '.
                   ' > div#titleMeta > div#cover > div.imgShadow > img ')->attr('src');
    };
    warn "$@" if $@;
    return if $@;
    return $found;
}

package main;
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

sub handler {
    my $journal = shift;
    my $url = $journal->{url};
    return [ 'elsevier', $url ] if $url && $url =~ /elsevier/;
    return [ 'wiley', $url ] if $url && $url =~ /wiley/;
    return;
}

sub handle_all {
    my $all = shift;
    for my $journal (@$all) {
        my $handler = handler($journal) or next;
        say $journal->{identifier};
        my ($type,$url) = @$handler;
        my $this = $ua->get("$dest/journal/$journal->{identifier}.json" => \%hdrs)->res->json;
        if ($this->{files} && @{$this->{files}}) {
            say "have files for $journal->{identifier} already";
            next;
        }
        my $dom = $ua->get($url)->res->dom;
        my $img_url = Parser->$type($dom);
        say "skipppng ".$journal->{url} unless $img_url;
        next unless $img_url;
        say $img_url;
        my $tx = $ua->post("$dest/journal/files/$journal->{identifier}" => \%hdrs => form => { file_url => $img_url } );
        my $res = $tx->success or do { warn $tx->error; next; };
        warn "error : ".$res->code.$res->body unless $res->code==200;
        sleep 5;
    }
}

handle_all($all);

