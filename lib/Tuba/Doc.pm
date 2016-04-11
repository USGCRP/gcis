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
limit 10"
        },
        { desc = "Find all articles cited by both the Third National Climate Assessment and the Human Health Assessment.",
          code => <<'SPARQL1', 

PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX cito: <http://purl.org/spar/cito/>
PREFIX dbpprop: <http://dbpedia.org/property/>

select ?s FROM <http://data.globalchange.gov> where {
   ?s a gcis:AcademicArticle .
   ?s cito:isCitedBy ?nca3 .
   ?nca3 dcterms:identifier "nca3" .
   ?s cito:isCitedBy ?health_assessment .
   ?health_assessment dcterms:identifier "usgcrp-climate-human-health-assessment-2016",
}
SPARQL1
        },
        { desc => "Identify the year of the earliest publication cited in the Third National Climate Assessment.",
          code => <<'SPARQL2',

PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX cito: <http://purl.org/spar/cito/>
PREFIX dbpprop: <http://dbpedia.org/property/>

select min(?pubYear as ?Publication_Year) FROM <http://data.globalchange.gov> where { 
   ?s cito:isCitedBy ?nca3 .
   ?nca3 dcterms:identifier "nca3" .
   ?s dbpprop:pubYear ?pubYear
}
SPARQL2
        },
        { desc => "List 10 figures and datasets from which they were derived.",
          code =>
"select ?figure ?dataset FROM <http://data.globalchange.gov>
where {
 ?figure gcis:hasImage ?img .
 ?img prov:wasDerivedFrom ?dataset
}
limit 10",
        },
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

