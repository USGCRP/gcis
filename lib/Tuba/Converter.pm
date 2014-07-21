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
use Text::Format;
use Tuba::Log;
use Mojo::Util qw/xml_escape/;
use Encode qw/encode decode/;
use Path::Class qw/file/;

has 'ttl';  # Turtle
has 'base'; # uri_base

sub _tmp {
    my $content = shift;
    my $tmp = File::Temp->new;
    print $tmp encode('UTF-8',$content);
    $tmp->close;
    return $tmp;
}

sub output {
    my $s = shift;
    my %a = @_;
    my $fmt = $a{format} or die 'no format given';
    my $title = $a{title};

    if ($fmt eq 'svg') {
        my $dot = $s->output(format => 'dot');
        my $width = 40;
        my $truncate = 350;
        my $fmt = Text::Format->new({columns => $width});
        my $filtered = '';
        for my $line (split /\n/, $dot) {
          if ($line =~ m/label="(.*?)"/ && $line !~ /Model:/) {
            my $labeltext = $1;
            $labeltext =~ s[/][/ ]g;
            my $newlabel = $fmt->format($labeltext);
            $newlabel =~ s/\n/\\n/g;
            $labeltext =~ s[/ ][/]g;
            if (length($newlabel) > $truncate) {
                $newlabel = substr($newlabel,0,$truncate - 2).'...';
            }
            $line =~ s/label=".*?"/label="$newlabel"/;
          }
          $filtered .= $line."\n";
        }
        my $in = _tmp($filtered);
        my $errs = File::Temp->new;
        my $cmd = "dot -Nwidth=3 -Nheight=1.5 -Nfontsize=8 -Nfixedsize=true -Tsvg $in 2>$errs";
        my $got = `$cmd` or do {
            logger->error("Error converting to svg ".join '',<$errs>);
            return "error converting to svg";
        };
        $got = decode('UTF-8',$got);
        if ($title) {
            $title = xml_escape($title);
            $got =~ s/<title>(\S+)<\/title>/<title>svg : $title<\/title>/
        }
        return $got;
    }
    my $base = $s->base or die "no base";
    # TODO use rdflib in memory.
    my $fp = _tmp($s->ttl);
    my $errs = File::Temp->new;
    my $cmd = "rapper -i turtle -o $fmt $fp $base 2>$errs";
    logger->info("running $cmd");
    my $got = `$cmd`;
    # rapper uses escape sequences, cannot output unicode.
    $got =~ s/\\u([[:xdigit:]]{1,4})/chr(eval("0x$1"))/egis;
    $got = encode('UTF-8',$got) unless $fmt =~ /^(dot|rdfxml)/; # some are already encoded
    if (!$got || $@) {
        logger->error("Errors running $cmd :\n ".join '',<$errs>);
        logger->info("errors $@") if $@;
        logger->info("Input ($fp) : ".file($fp)->slurp);
        return "error converting to $fmt";
    }
    return $got;
}

1;

