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
my $page  = $ARGV[2] || '1';

my $ua = Mojo::UserAgent->new;

my $tx = $ua->get("$base/report.json?page=$page");
my $res = $tx->success or die $tx->error;
my $all = $res->json;

my $dir;
my $errs;
my $ok;
my $out;
for (@$all) {
    $ok = 0;
    $dir = File::Temp->newdir;
    chdir $dir;
    my $identifier = $_->{identifier};
    my $url = $_->{url} or next;
    $errs = File::Temp->new;
    say "Doing $identifier ($url)";
    $out = `curl -q '$url' > ./out.pdf 2>$errs`;
    -e './out.pdf' or next;
    $out = `gm convert -resize 600x400 out.pdf[0] out.jpg 2>$errs`;
    -e './out.jpg' or next;
    $out = `curl -T ./out.jpg -u $creds $base/report/files/$identifier 2> $errs`;
    $ok = 1 unless $?;
} continue {
    if (!$ok) {
        #say "\n\n$out\nerrors : ", file("$errs")->slurp;
        say "fail";
    } else {
        chdir '/tmp';
        undef $dir;
        undef $errs;
    }
}


