package Tuba::Importer;
use Mojo::Base qw/Tuba::Controller/;
use JSON::XS;
use Path::Class qw/file/;
use Tuba::Importer::Processor::Journals;
use Tuba::Importer::Processor::Findings;
use Tuba::Importer::Processor::Datasets;
use Tuba::Importer::Processor::Ant;

sub _data {
    my $c = shift;
    my $json = JSON::XS->new();
    my $goog_dir = $c->config('goog_dir') || '/var/local/projects/raw/data/goog';
    my $goog_file = $c->config('goog_file') || 'goog.json';
    return $json->decode(scalar file("$goog_dir/$goog_file")->slurp);
}

sub form {
    my $c = shift;
    my $data = $c->_data();
    my @spreadsheets = keys %$data;
    my %worksheets;
    for my $s (@spreadsheets) {
        $worksheets{$s} = $data->{$s}{_worksheets};
    }
    $c->stash(spreadsheets => \@spreadsheets);
    $c->stash(worksheets => \%worksheets);
    $c->render;
}

sub _error {
    my $c = shift;
    my $error = shift;
    $c->flash(error => $error);
    return $c->redirect_to('import_form');
}

sub process_import {
    my $c = shift;
    my $spreadsheet = $c->param('spreadsheet') or return $c->_error('no spreadsheet selected');
    my $worksheet = $c->param('worksheet') or return $c->_error('no worksheet selected');
    my $import = $c->_data->{$spreadsheet}{$worksheet} or do {
        $c->flash(error => "could not find $spreadsheet : $worksheet");
        return $c->redirect_to('import_form');
    };
    my $processor = $c->_find_processor($spreadsheet, $worksheet)
        or return $c->_error("No processor configured for $spreadsheet : $worksheet");

    $processor->audit_user($c->user);
    $processor->audit_note("$spreadsheet : $worksheet");
    $processor->update_only(1) if $c->param('update_only');

    my $status = $processor->process(data => $c->_data->{$spreadsheet}{$worksheet});

    return $c->render(p => $processor, template => 'importer/status');
}

sub _find_processor {
    my $c = shift;
    my ($spreadsheet, $worksheet) = @_;

    #Spreadsheet, worksheet, Ant target                                                                                                                                                 
    #'NCA Graphics Tracking','GCIS Provenance', sync-figures                                                                                                                            
    #'Journals_perBrian','Sheet1', sync-journals #Broken                                                                                                                                
    #'Articles','Sheet1', sync-articles                                                                                                                                                 
    #'Organizations','Sheet1', sync-organizations #Broken                                                                                                                               
    #'nca3draft.canonicalURIs.chapters','Sheet 1', sync-chapters                                                                                                                        
    #];

    my @a = ( spreadsheet => $spreadsheet, worksheet => $worksheet );
    for ($spreadsheet) {
        /journals/i               and return Tuba::Importer::Processor::Journals->new(@a);
        /findings/                and return Tuba::Importer::Processor::Findings->new(@a);
        /a-level datasets/i       and return Tuba::Importer::Processor::Datasets->new(@a);
        /nca graphics tracking/i  and return Tuba::Importer::Processor::Ant->new(@a, target => "sync-figures", antdir => $c->config('ant_dir'));
        /canonicalURIs.chapters/i and return Tuba::Importer::Processor::Ant->new(@a, target => "sync-chapters", antdir => $c->config('ant_dir'));
    }
    return;
}

1;
