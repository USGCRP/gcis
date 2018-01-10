#!perl

use FindBin;
use lib $FindBin::Bin;
use tinit;
use Test::MBD qw/-autostart/;
use Test::More;
use Test::Mojo;
use strict;

use_ok 'Tuba';

my $t = Test::Mojo->new('Tuba');
$t->ua->max_redirects(2);
$t->post_ok("/login" => form => { user => "unit_test", password => "anything" })->status_is(200);

my $base = $t->ua->server->url;
$base =~ s[/$][];

$t->get_ok('/report.json')->status_is(200)->json_is([]);

my @reports = map +{
     identifier            => "report-number-$_",
     title                 => "This is report number $_",
     url                   => "http://example.com/report/$_",
     doi                   => "10.123/91023-$_",
     _public               => 1,
     report_type_identifier => 'report',
     summary               => "This is a really interesting report about $_.  Temperature is $_°F (± 12½).",
     frequency             => "1 year",
     publication_year      => 2000 + $_,
     topic                 => "nothing",
     in_library            => 1,
     contact_note          => "notey note",
     contact_email         => "note\@note.com"
    }, 1..5;

$t->post_ok("/report" => json => $_)->status_is(200) for @reports;

$t->get_ok('/report.json')->status_is(200)->json_is(
    [
        map +{ %$_, uri => "/report/$_->{identifier}", href => "$base/report/$_->{identifier}.json" }, @reports
    ]
);

my $expect = <<"CSV";
uri,href,identifier,_public,contact_email,contact_note,doi,frequency,in_library,publication_year,report_type_identifier,summary,title,topic,url
/report/report-number-1,$base/report/report-number-1,report-number-1,1,note\@note.com,"notey note",10.123/91023-1,"1 year",1,2001,report,"This is a really interesting report about 1.  Temperature is 1°F (± 12½).","This is report number 1",nothing,http://example.com/report/1
/report/report-number-2,$base/report/report-number-2,report-number-2,1,note\@note.com,"notey note",10.123/91023-2,"1 year",1,2002,report,"This is a really interesting report about 2.  Temperature is 2°F (± 12½).","This is report number 2",nothing,http://example.com/report/2
/report/report-number-3,$base/report/report-number-3,report-number-3,1,note\@note.com,"notey note",10.123/91023-3,"1 year",1,2003,report,"This is a really interesting report about 3.  Temperature is 3°F (± 12½).","This is report number 3",nothing,http://example.com/report/3
/report/report-number-4,$base/report/report-number-4,report-number-4,1,note\@note.com,"notey note",10.123/91023-4,"1 year",1,2004,report,"This is a really interesting report about 4.  Temperature is 4°F (± 12½).","This is report number 4",nothing,http://example.com/report/4
/report/report-number-5,$base/report/report-number-5,report-number-5,1,note\@note.com,"notey note",10.123/91023-5,"1 year",1,2005,report,"This is a really interesting report about 5.  Temperature is 5°F (± 12½).","This is report number 5",nothing,http://example.com/report/5
CSV

$t->get_ok("/report.csv")->status_is(200)->content_is($expect);
#$t->get_ok("/report.json?per_page=2")->status_is(200)->content_is('report-number-3');


my $expect2 = <<"CSV";
uri,href,identifier,_public,contact_email,contact_note,doi,frequency,in_library,publication_year,report_type_identifier,summary,title,topic,url
/report/report-number-1,$base/report/report-number-1,report-number-1,1,note\@note.com,"notey note",10.123/91023-1,"1 year",1,2001,report,"This is a really interesting report about 1.  Temperature is 1°F (± 12½).","This is report number 1",nothing,http://example.com/report/1
/report/report-number-2,$base/report/report-number-2,report-number-2,1,note\@note.com,"notey note",10.123/91023-2,"1 year",1,2002,report,"This is a really interesting report about 2.  Temperature is 2°F (± 12½).","This is report number 2",nothing,http://example.com/report/2
CSV

$t->get_ok("/report.csv?per_page=2")->status_is(200)->content_is($expect2);

$t->get_ok('/image')->status_is(200);
$t->get_ok('/image.json')->status_is(200)->json_is([]);
$t->get_ok('/journal')->status_is(200);
$t->get_ok('/journal.json')->status_is(200)->json_is([]);
$t->get_ok('/article')->status_is(200);
$t->get_ok('/article.json')->status_is(200)->json_is([]);

$t->delete_ok("/report/$_->{identifier}")->status_is(200) for @reports;
done_testing();

1;

