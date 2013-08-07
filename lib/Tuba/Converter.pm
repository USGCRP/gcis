=head1 NAME

Tuba::Converter -- convert between various formats.

=head1 SYNOPSIS

 # convert from tuba to ntriples
 print Tuba::Converter->new(ttl => $turtle)->output(format => "nt");

=head1 DESCRIPTION

Given Turtle input, convert to a variet of output formats.

Support formats (from rapper --help) :

    ntriples        N-Triples (default)
    turtle          Turtle
    rdfxml-xmp      RDF/XML (XMP Profile)
    rdfxml-abbrev   RDF/XML (Abbreviated)
    rdfxml          RDF/XML
    rss-1.0         RSS 1.0
    atom            Atom 1.0
    dot             GraphViz DOT format
    json-triples    RDF/JSON Triples
    json            RDF/JSON Resource-Centric

Also from 'dot', we go through graphviz to get to svg.

=cut

package Tuba::Converter;
use Mojo::Base qw/-base/;
use Tuba::Log;

has 'ttl';  # Turtle
has 'base'; # uri_base

sub _tmp {
    my $content = shift;
    my $tmp = File::Temp->new();
    print $tmp $content;
    $tmp->close;
    return $tmp;
}

sub output {
    my $s = shift;
    my %a = @_;
    my $fmt = $a{format} or die 'no format given';
    if ($fmt eq 'svg') {
        my $dot = $s->output(format => 'dot');
        my $in = _tmp($dot);
        my $errs = File::Temp->new;
        my $cmd = "dot -Tsvg $in 2>$errs";
        my $got = `$cmd` or do {
            logger->error("Error converting to svg ".join '',<$errs>);
            return "error converting to svg";
        };
        return $got;
    }
    my $base = $s->base or die "no base";
    # TODO use rdflib in memory.
    my $fp = _tmp($s->ttl);
    my $errs = File::Temp->new;
    my $cmd = "rapper -i turtle -o $fmt $fp $base 2>$errs";
    logger->info("running $cmd");
    my $got = `$cmd`;
    if (!$got || $@) {
        logger->error("Errors running $cmd :\n ".join '',<$errs>);
        return "error converting to $fmt";
    }
    logger->info("got $@");
    return $got;
}

1;

