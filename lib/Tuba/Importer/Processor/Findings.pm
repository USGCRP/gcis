package Tuba::Importer::Processor::Findings;
use Mojo::Base qw/-base/;
use Tuba::DB::Objects qw/-nicknames/;
use List::MoreUtils qw/mesh/;
use Data::Dumper;

has 'spreadsheet';
has 'worksheet';

has rows_processed => 0;
has errors => sub { [] };
has warnings => sub { [] };

has 'audit_user';
has 'audit_note';

has 'update_only';
has 'status';

sub _note_error {
    my $self = shift;
    my ($msg,$index) = @_;
    push @{ $self->errors }, { row => $index, message => $msg };
}

sub _audit_info {
    my $self = shift;
    my $index = shift;
    return ( audit_user => $self->audit_user, audit_note => $self->audit_note." row $index" ) if $index;
    return ( audit_user => $self->audit_user, audit_note => $self->audit_note);
}

sub process {
    no warnings 'uninitialized';
    my $self = shift;
    my %args = @_;
    my $data = $args{data} or die "missing data";
    my %a = ( audit_user => $self->audit_user, audit_note => $self->audit_note );

    my $index = 0;
    my @labels;
    for my $row (@$data) {
        next unless $row;
        unless (@labels) {
            @labels = map lc, @$row;
            next;
        }
        my %record = mesh @labels, @$row;
        unless ($record{identifier}) {
            $self->_note_error("no identifier for finding", $index);
            next;
        }
        my $finding = Finding->new(identifier => $record{identifier});
        $finding->load(speculative => 1);
        $finding->ordinal($record{ordinal});
        $finding->statement($record{finding});
        my $pub = $record{chapter};
        if ($pub =~ m[chapter/(.*)$]) {
            $finding->chapter($1);
        } else {
            $finding->chapter(undef);
        }
        if ($pub =~ m[report/([^/]+)/]) {
            $finding->report($1);
        } else {
            $finding->report(undef);
        }
        $finding->save(changes_only => 1, $self->_audit_info($index)) or do {
            $self->_note_error($finding->error, $index);
            next;
        };
        if (my $kws = $record{'gcmd science keywords'} ) {
             for my $kw (split /\s*,\s*/, $kws) {
                 my ($category, $topic, $term, $one, $two, $three) = split /\s*>\s*/, $kw;
                 my $k = Keyword->new(category => $category, topic => $topic, term => $term, level1 => $one, level2 => $two, level3 => $three);
                 $k->load(speculative => 1) or $k->save($self->_audit_info) or do { $self->_note_error($k->error, $index); next };
                 FindingKeywordMap->new(finding => $record{identifier}, keyword => $k->id)->save($self->_audit_info)
                    or $self->_note_error("could not add keywords to findings");
             }
        }
    } continue {
        $index++;
        $self->rows_processed($self->rows_processed + 1);
    }

    return $self->status('ok');
}

1;

