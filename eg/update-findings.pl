#!/usr/bin/env perl
use Mojo::UserAgent;
use Path::Class qw/file/;
use Data::Dumper;

use feature qw/:all/;
use strict;
use warnings;

#my $dest    = "http://localhost:3000";
my $src     = "http://gcis-dev-front.joss.ucar.edu/raw";

my $which = $ARGV[0] or die "Usage $0 [local|dev|test|prod]\n";
my $dest = {
  local => "http://localhost:3000",
  dev   => "https://data.gcis-dev-front.joss.ucar.edu",
  test  => "https://data.gcis-test-front.joss.ucar.edu",
  prod  => "https://data.globalchange.gov",
  }->{$which};

say "connecting to $dest";

my $which_key = $dest =~ /gcis-dev/                ? '.gcis_api_key.dev'
              : $dest =~ /gcis-test/               ? '.gcis_api_key.test'
              : $dest =~ /data.globalchange.gov$/ ? '.gcis_api_key.prod'
              :   die "don't know which key to use for $dest";
my $keyfile = "$ENV{HOME}/".$which_key;
my $key     = file($keyfile)->slurp;
chomp $key;
my $ua      = Mojo::UserAgent->new();
$ua->max_redirects(3);
my %hdrs = ("Accept" => "application/json",
            "Authorization" => "Basic $key");

sub get {
    my $path = shift;
    my $url;
    $url = $path;
    $url = "$dest$path" unless $path =~ /^http/;
    my $tx = $ua->get($url => \%hdrs);
    my $res = $tx->success or die $tx->error;
    my $json = $res->json or die "no json from $url : ".$res->body;
    return $res->json;
}

sub post {
    my $path = shift;
    my $data = shift;
    my $tx = $ua->post("$dest$path" => \%hdrs => json => $data );
    my $res = $tx->success or die $tx->error.$tx->req->to_string;
    my $json = $res->json or die "no json : ";
    return $res->json;
}

my ($obj,$new);

my $list = get("/report/nca3draft/finding?all=1");

for my $finding (@$list) {
    my $num = $finding->{chapter}{number} or next;
    my $ord = $finding->{ordinal} or next;
    my $raw_url = sprintf(qq[$src/json/r/<http://data.globalchange.gov/report/nca2013/chapter/%d/traceable_account/%d>], $num,$ord);
    my $raw = get($raw_url);
    delete $finding->{chapter};
    $finding->{uncertainties} = $raw->{newInformationAndRemainingUncertainties}[0];
    $finding->{evidence} = $raw->{descriptionOfEvidenceBase}[0];
    $finding->{confidence} = $raw->{assessmentOfConfidenceBasedOnEvidence}[0];
    next unless grep defined, @$finding{qw/uncertainties evidence confidence/};
    post("/report/nca3draft/finding/".$finding->{identifier} => $finding);
    print "$num.$ord\n";
}

