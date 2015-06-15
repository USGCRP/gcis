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
        },
        ceos => {
            Mission => sub { "http://database.eohandbook.com/database/missionindex.aspx#".(uc substr($_[0],0,1)) },
            missionID => sub { "http://database.eohandbook.com/database/missionsummary.aspx?missionID=".$_[0] },
            Instrument => sub { "http://database.eohandbook.com/database/instrumentindex.aspx#".(uc substr($_[0],0,1)) },
            instrumentID => sub { "http://database.eohandbook.com/database/instrumentsummary.aspx?instrumentID=$_[0]" },
        },
        gcmd => {
            platform => sub { "http://gcmdservices.gsfc.nasa.gov/static/kms/concept/".$_[0] },
            instrument => sub { "http://gcmdservices.gsfc.nasa.gov/static/kms/concept/".$_[0] },
        },
        esg => {
            model => sub { "https://esg.llnl.gov:8443/metadata/advancedDatasetSearch.do?d_scenario=any&d_frequency=any&d_offset=0&d_model=".$_[0] },
            scenario => sub { "https://esg.llnl.gov:8443/metadata/advancedDatasetSearch.do?d_model=any&d_frequency=any&d_offset=0&d_scenario=".$_[0] },
            model_run => sub { "https://esg.llnl.gov:8443/metadata/showObject.do?id=$_[0]" },
        },
        ornl => {
            dataset => sub {
                "http://mercury.ornl.gov/oai/provider?verb=GetRecord&metadataPrefix=oai_dif&identifier=".shift;
            },
        },
        nsidc => {
            dataset => sub {
                 "http://nsidc.org/api/dataset/2/oai?verb=GetRecord&metadataPrefix=dif&identifier=".shift;
            },
        },
        dbpedia => {
            resource => sub {
                "http://wikipedia.org/wiki/".shift
            },
        },
    };
    my $lex = $lookup->{ $s->lexicon_identifier } or return;
    my $ctx = $lex->{ $s->context } or return;
    return $ctx->( $s->term );
}

sub same_as {
    my $s = shift;
    my $lookup =  {
        dbpedia => {
            resource => sub {
                "http://dbpedia.org/resource/".shift
            },
        },
    };
    my $lex = $lookup->{ $s->lexicon_identifier } or return;
    my $ctx = $lex->{ $s->context } or return;
    return $ctx->( $s->term );
}

sub uri {
    my $s = shift;
    my $c = shift or die "missing controller";
    my $path = join '/', 'lexicon', $s->lexicon_identifier, $s->context, $s->term;
    my $url = Mojo::URL->new->path($path);
    $url->base($c->req->url->base);
    return $url;
}

1;

