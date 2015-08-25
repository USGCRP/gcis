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
        { desc => "List all of the chapter findings from the Third National Climate Assessment.",
          code => <<'SPARQL',

PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX dbpedia: <http://dbpedia.org/resource/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

SELECT
    str($findingNumber) as $findingNumber 
    str($statement) as $statement 
    $finding 
 
FROM <http://data.globalchange.gov>
WHERE {
    $report dcterms:title "Climate Change Impacts in the United States: The Third National Climate Assessment"^^xsd:string .
    $report a gcis:Report .
    $report gcis:hasChapter $chapter .
    $finding gcis:isFindingOf $chapter .
    $finding dcterms:description $statement .
    $finding dbpedia:Natural_number $ordinal .
    $finding gcis:findingNumber $findingNumber .
    $finding a gcis:Finding .
    $chapter gcis:chapterNumber $chapterNumber .
}
ORDER BY $chapterNumber $ordinal
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

