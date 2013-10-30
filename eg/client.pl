#!/usr/bin/env perl

use Net::Google::Spreadsheets;
use Data::Dumper;
use v5.14;

use lib './lib';
use Tuba::Client;

my $service = Net::Google::Spreadsheets->new(
username => $ENV{GOOG_USER},
password => $ENV{GOOG_PASS}
) or die 'login failed';

my $sp = $service->spreadsheet( { key => '0AtK8bPV8KmjldDh5YjNqdXVDVGU1dlhKUVQyVXgxa2c' });
my $wk = $sp->worksheet({ title => 'Short-names' }) or die 'no worksheet';
my @rows = map $_->content, $wk->rows;

#---------------------------------------------------------------------------------#
#my $h = {
#  'shortname' => 'local-level-adaptation-activities',
#  'tablenum' => 'Table 28.6',
#  'nca3draftchapter' => 'Adaptation',
#  'suggesteduri' => '/table/local-level-adaptation-activities',
#  'imageid' => '/image/8e638a2a-1161-4641-b6e8-0ad2471d9aa7',
#  'note' => '',
##  'uri' => '/figure/local-level-adaptation-activities'
# };

#my $client = Tuba::Client->new;
#my $client = Tuba::Client->new(
#    url => 'http://data.gcis-test-front.joss.ucar.edu',
#    keyfile => $ENV{HOME}.'/.gcis_api_key.test',
#);
my $client = Tuba::Client->new(
    url => 'http://data.globalchange.gov',
    keyfile => $ENV{HOME}.'/.gcis_api_key.prod',
);


my $got = $client->get('/login');
my $chapters = $client->get('/report/nca3draft/chapter?all=1');
my %num2id = map { ( $_->{number} || '' ) => $_->{identifier} } @$chapters;

for my $h (@rows) {
    say Dumper($h);
    my ($chapternum) = $h->{tablenum} =~ / (\d+)\./ or die "no chapter in $h->{tablenum}";
    my $chapter = $num2id{$chapternum} or die "no chapter";
    my ($ordinal) = $h->{tablenum} =~ /\.(\d+)$/ or die "no ordinal in $h->{tablenum}";
    $got = $client->post("/report/nca3draft/chapter/$chapter/table",
        {
            identifier => $h->{shortname},
            report_identifier => 'nca3draft',
            chapter_identifier => $chapter,
            ordinal => $ordinal,
        });
}

