=head1 NAME

Tuba::Doc -- online docs for tuba

=cut

package Tuba::Doc;

use Mojo::Base qw/Tuba::Controller/;

sub examples {
    my $c = shift;
    my $sparql_url = $c->req->url->clone->to_abs;
    $sparql_url->path->parts(['sparql']);

    my $global_slr = $sparql_url->clone;
    $global_slr->path(q[/report/nca3/chapter/our-changing-climate/figure/past-and-projected-changes-in-global-slr]);

    my $sparql = [
        { desc => "List URLs for 10 figures.",
          code => 
"select * FROM <http://data.globalchange.gov>
where { ?s a gcis:Figure }
limit 10",
        },
        { desc => "List all of the findings from the Third National Climate Assessment.",
          code => <<'SPARQL',

PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX dbpedia: <http://dbpedia.org/resource/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX gcis: <http://data.globalchange.gov/gcis.owl#>

SELECT 
	?Chapter_Title
	?findingNumber
	?chapterNumber
	?figureOfChapter_Text
	?Finding_Text
	?Finding_ID
{
  { 
    SELECT DISTINCT
    	str(?chapterTitle) as ?Chapter_Title
    	str(?findingNumber) as ?findingNumber
    	str(?chapterNumber) as ?chapterNumber
    	xsd:integer(SUBSTR(?findingNumber,3)) as ?figureOfChapter
    	SUBSTR(?findingNumber,3) as ?figureOfChapter_Text
    	str(?findingStatement) as ?Finding_Text
    	?finding as ?Finding_ID
	WHERE {
		<http://data.globalchange.gov/report/nca3> gcis:hasChapter ?chapter .
		?chapter dcterms:title ?chapterTitle .
		?chapter gcis:chapterNumber ?chapterNumber .
		?chapter gcis:hasFinding ?finding .
		?finding gcis:findingNumber ?findingNumber .
		?finding gcis:findingStatement ?findingStatement .
		FILTER(?chapterNumber < 10)
	} ORDER BY ?chapterNumber ?figureOfChapter
  } UNION {
	SELECT DISTINCT
		str(?chapterTitle) as ?Chapter_Title
    	str(?findingNumber) as ?findingNumber
    	str(?chapterNumber) as ?chapterNumber
		xsd:integer(SUBSTR(?findingNumber,4)) as ?figureOfChapter
    	SUBSTR(?findingNumber,4) as ?figureOfChapter_Text
		str(?findingStatement) as ?Finding_Text
		?finding as ?Finding_ID
	WHERE {
		<http://data.globalchange.gov/report/nca3> gcis:hasChapter ?chapter .
		?chapter dcterms:title ?chapterTitle .
		?chapter gcis:chapterNumber ?chapterNumber .
		?chapter gcis:hasFinding ?finding .
		?finding gcis:findingNumber ?findingNumber .
		?finding gcis:findingStatement ?findingStatement .
		FILTER(?chapterNumber >= 10)
	} ORDER BY ?chapterNumber ?figureOfChapter
  }
}
SPARQL
        },
        {
          desc => "List 10 figures and datasets from which they were derived.",
          code =>
"select ?figure ?dataset FROM <http://data.globalchange.gov>
where {
 ?figure gcis:hasImage ?img .
 ?img prov:wasDerivedFrom ?dataset
}
limit 10"
}
    ];
    for (@$sparql) {
        my $url = $sparql_url->clone;
        $url->query(query => $_->{code});
        $_->{link} = $url;
    }
    $c->stash(sparql_url => $sparql_url);
    $c->stash(sparql => $sparql);
    $c->respond_to(
        json => { json => $sparql },
        any => sub { shift->render }
    );
}

sub api_reference {
  my $c = shift;
  $c->respond_to(
    json => sub {
      my $c = shift;
      $c->render(jsonxs => Tuba::DocManager->new->as_swagger($c), handler => 'json_canonical');
    },
    yaml => sub {
      my $c = shift;
      $c->render_yaml(Tuba::DocManager->new->as_swagger($c));
    },
    html => sub {
      my $trying;
      if (my $try = $c->param('try')) {
        $trying = $c->app->routes->lookup($try);
      }
      $c->stash(trying => $trying);
      return unless $trying;
      my @placeholders;
      while ($trying) {
        for my $n (@{$trying->pattern->tree}) {
          next unless @$n == 2;
          next unless $n->[0] =~ /^(placeholder|wildcard|relaxed)$/;
          unshift @placeholders, $n->[1];
        }
        $trying = $trying->parent;
      }
      $c->stash(placeholders => \@placeholders);
    }
  );
}

1;

