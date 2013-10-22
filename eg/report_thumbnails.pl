#!/usr/bin/env perl

use Mojo::JSON;
use Mojo::UserAgent;
use File::Temp;
use Path::Class qw/file/;
use v5.14;

my $base  = $ARGV[0] || 'http://localhost:3000';
my $which = $ARGV[1] || 'local';
my $creds = file("$ENV{HOME}/.gcis_creds.$which")->slurp;
chomp $creds;
my $identifier  = $ARGV[2];

my $ua = Mojo::UserAgent->new;

my $all;

if ($identifier) {
    my $tx = $ua->get("$base/report/$identifier.json");
    my $res = $tx->success or die $tx->error;
    $all = [ $res->json ];
} else {
    my $tx = $ua->get("$base/report.json?all=1");
    my $res = $tx->success or die $tx->error;
    $all = $res->json;
}

sub done {
    my $identifier = shift;
    my $tx = $ua->get("$base/report/$identifier.json");
    my $res = $tx->success or do { warn $tx->error; return; };
    return 1 if $res->json->{files} && @{ $res->json->{files} };
    return 0;
}

my $dir;
my $errs;
my $ok;
my $out;
my $done;
for (@$all) {
    $ok = 0;
    $done = 0;
    $dir = File::Temp->newdir;
    chdir $dir;
    my $identifier = $_->{identifier};
    say "# $identifier :";
    do { $done=1; next; } if done($identifier);
    my $url = $_->{url} or next;
    $errs = File::Temp->new;
    $out = `curl -m300 -q '$url' > ./out.pdf 2>$errs`;
    -e './out.pdf' or next;
    chomp(my $type = `file ./out.pdf`);
    unless ($type =~ /PDF/) {
        $out = "File is : $type";
        undef $errs;
        next;
    }
    $out = `gm convert -resize 600x400 out.pdf[0] cover.png 2>$errs`;
    -e './cover.png' or next;
    $out = `curl -T ./cover.png -u $creds $base/report/files/$identifier/ 2> $errs`;
    $ok = 1 unless $?;
} continue {
    chdir '/tmp';
    if ($done) {
        say "# skipped";
    } elsif (!$ok) {
        say "# $out";
        say "# errors : ", file("$errs")->slurp if $errs && -e $errs;
        say "not ok";
    }
    say "ok";
    undef $dir;
    undef $errs;
}


