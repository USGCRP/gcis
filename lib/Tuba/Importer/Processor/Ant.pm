package Tuba::Importer::Processor::Ant;
use Mojo::Base qw/Tuba::Importer::Processor/;
use File::Temp;
use Path::Class qw/file/;

has 'target';
has 'antdir' => '/usr/local/projects/release/gcisbaseline';

sub process {
    my $self = shift;

    my $stdout = File::Temp->new;
    my $stderr = File::Temp->new;

    my $cmd = sprintf('cd %s && ant %s > %s 2> %s',
            $self->antdir,
            $self->target,
            "$stdout",
            "$stderr");
    $stdout->close;
    $stderr->close;

    if (system($cmd)==0) {
        $self->_note_info(scalar file("$stdout")->slurp);
        $self->_note_info(scalar file("$stderr")->slurp);
        return $self->status('ok');
    }

    $self->_note_info(scalar file("$stdout")->slurp);
    $self->_note_info(scalar file("$stderr")->slurp);

    return $self->status('ok');
}

1;

