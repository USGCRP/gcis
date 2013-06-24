package Tuba::Importer;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use JSON::XS;
use Path::Class qw/file/;

sub form {
    my $c = shift;
    my $goog_dir = $c->config('goog_dir') || '/var/local/projects/raw/data/goog';
    my $goog_file = $c->config('goog_file') || 'goog.json';
    my $json = JSON::XS->new();
    my $data = $json->decode(scalar file("$goog_dir/$goog_file")->slurp);
    my @spreadsheets = keys %$data;
    my %worksheets;
    for my $s (@spreadsheets) {
        $worksheets{$s} = $data->{$s}{_worksheets};
    }
    $c->stash(spreadsheets => \@spreadsheets);
    $c->stash(worksheets => \%worksheets);
    $c->render;
}

1;
