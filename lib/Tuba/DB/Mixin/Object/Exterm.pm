package Tuba::DB::Object::Exterm;
# package Tuba::DB::Mixin::Object::Exterm;
use strict;

sub native_url {
    my $s = shift;
    my $lookup = {
        podaac => {
            dataset => sub { "http://podaac.jpl.nasa.gov/dataset/$_[0]"; },
            datasetId => sub { "http://podaac.jpl.nasa.gov/ws/search/dataset?datasetId=$_[0]" },
            Platform => sub { "http://podaac.jpl.nasa.gov/datasetlist?ids=Platform&values=$_[0]" },
        }
    };
    my $lex = $lookup->{ $s->lexicon_identifier } or return;
    my $ctx = $lex->{ $s->context } or return;
    return $ctx->( $s->term );
}

1;

