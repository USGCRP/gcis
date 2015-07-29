=head1 NAME

Tuba::DocManager -- manage documentation for routes.

=cut

package Tuba::DocManager;
use Mojo::Base qw/-base/;
use Tuba::RouteDoc;
use Tuba::RouteParam;
use Mojo::ByteStream qw/b/;

our %RouteDoc = (
  uuid => {
    brief => "Generate a UUID.",
    description => b(q[<p>Generate version 4 Universally Unique Identifiers.  The algorithm used for this
    is described <a target="_blank" href="https://en.wikipedia.org/wiki/UUID#Version_4_.28random.29">here</a>.
    </p>]),
    params      => [
        {
          name        => "count",
          type        => "integer",
          description => "Number of UUIDs to generate (max 1000)"
        }
    ]
  },
  list_report => {
    tags        => [qw/report/],
    brief       => "Get a list of reports.",
    description => "List the reports, 20 per page.",
    note        => _common_list_note(),
    params      => [
      _common_list_params('reports'),
      {
        name => 'report_type',
        description =>
          'The type of report.  Currently : report, assessment, technical_input, or indicator.',
        type => 'string.',
      }
    ],
    },
    list_chapter => {
        tags => [qw/report/],
        _list_defaults('chapter'),
        brief       => "List chapters in a report",
        description => "Get a list of chapters in a report."
    },
    list_finding => {
        tags => [qw/finding/],
        _list_defaults('finding'),
        brief       => "List findings in a chapter",
        description => "Get a list of findings in a chapter."
    },
    list_figure => {
        tags => [qw/figure/],
        _list_defaults('figure'),
        brief       => "List figures in a chapter",
        description => "Get a list of figures in a chapter."
    },
    list_figures_across_reports => {
        tags => [qw/figure/],
        _list_defaults('figure'),
        brief       => "List all figures",
        description => "List all the figures in GCIS."
    },
    list_table => {
        tags => [qw/table/],
        _list_defaults('table'),
        brief       => "List tables in a chapter",
        description => "Get a list of tables in a chapter."
    },
    list_reference_chapter => {
        tabs => [qw/reference/],
        _list_defaults('reference'),
        brief       => "List references in a chapter",
        description => "Get a list of references in a chapter."
        },
    list_all_findings => {
        tags => [qw/finding/],
        _list_defaults('finding', add => "in a report")
    },
   list_all_figures => {
          tags => [qw/figure/],
          _list_defaults('figure', add => "in a report")
   },
   list_all_tables => {
          tags => [qw/table/],
          _list_defaults('table', add => "in a report")
   },
   list_reference_report => {
      tags => [qw/reference/],
      _list_defaults('reference', add => "in a report")
   },

  image => { _list_defaults('image' ) },
  array => { _list_defaults('array', add => 'associated with a report') },
  webpage => { _list_defaults('webpage', add => 'associated with a report') },
  list_report_images => { _list_defaults('image', add => 'associated with a report') },
  book => { _list_defaults('book', add => 'associated with a report') },
  reference => { _list_defaults('reference', add => 'of a report') },
  show_publication => {
      brief => "Redirect to a particular publication.",
      description => "Given a numeric ID, redirect to the full URI of a publication.",
  },
  show_contributor => {
      brief => "Redirect to a particular contributor.",
      description => "Given a numeric ID, redirect to the full URI of a contributor.",
  },

  list_article => { _list_defaults('article') },
  list_journal => { _list_defaults('journal') },
  list_image => { _list_defaults('image') },
  list_array => { _list_defaults('array') },
  list_webpage => { _list_defaults('web page') },
  list_activity => { _list_defaults('activity') },
  list_person => { _list_defaults('person') },
  list_region => { _list_defaults('region') },
  list_dataset => { _list_defaults('dataset') },
  list_organization => { _list_defaults('organization') },
  list_book => { _list_defaults('book') },
  list_platform => { _list_defaults('platform') },
  list_gcmd_keyword => { _list_defaults('GCMD keyword', add => "in the GCIS", not_all => 1) },
  list_reference => { _list_defaults('reference', not_all => 1) },
  list_generic => { _list_defaults('generic publication' ) },
  list_instrument => { _list_defaults('instrument' ) },
  list_instrument_instance => { _list_defaults('instrument', add => 'on a platform' ) },
  list_project => { _list_defaults('project') },
  list_model => { _list_defaults('model') },
  list_model_run => { _list_defaults('model run') },
  list_model_runs_for_model => { _list_defaults('model run', add => "for a particular model") },
  list_model_runs_for_scenario => { _list_defaults('model run', add => "for a particular scenario") },
  list_scenario => { _list_defaults('scenario') },
  list_lexicon => { _list_defaults('lexicon') },

  show_report => { _show_defaults('report', withs => 1) },
  show_chapter => { _show_defaults('chapter', withs => 1) },
  show_platform => { _show_defaults('platform') },
  show_instrument => { _show_defaults('instrument') },
  show_instrument_instance => { _show_defaults('instrument', add => 'on a platform' ) },
  show_project => { _show_defaults('project') },
  show_model => { _show_defaults('model') },
  show_model_run => { _show_defaults('model run') },
  show_lexicon => { _show_defaults('lexicon') },
  model_run_lookup => { _show_defaults('model run') },
  show_scenario => { _show_defaults('scenario') },

  show_figure => { _show_defaults('figure', withs => 1, add => "in a chapter") },
  show_finding => { _show_defaults('finding', withs => 1, add => "in a chapter") },
  show_table => { _show_defaults('table', withs => 1, add => "in a chapter") },

  show_report_figure => { _show_defaults('figure', withs => 1) },
  show_report_finding => { _show_defaults('finding', withs => 1) },
  show_report_table => { _show_defaults('table', withs => 1) },

  show_article => { _show_defaults('article', withs => 1) },
  show_journal => { _show_defaults('journal') },
  show_image => { _show_defaults('image', withs => 1) },
  show_array => { _show_defaults('array', withs => 1) },
  show_webpage => { _show_defaults('web page', withs => 1) },
  show_book => { _show_defaults('book', withs => 1) },
  show_activity => { _show_defaults('activity') },
  show_person => { _show_defaults('person') },
  show_organization => { _show_defaults('organization') },
  show_gcmd_keyword => { _show_defaults('GCMD keyword') },
  show_region => { _show_defaults('region') },
  show_dataset => { _show_defaults('dataset') },
  dataset_doi => { brief => "Look up a dataset by DOI.", description => "Given a DOI, return a redirect to the GCIS dataset." },
  show_file => { _show_defaults('file') },
  show_reference => { _show_defaults('reference') },
  show_generic => { _show_defaults('generic publication') },

  personorcid => {
      brief => "Redirect to a person based on an ORCID.",
      description => "Given an ORCID, if there is a match, redirect to the person's URI.",
  },
  personname => {
      brief => "Redirect to a person based on a name",
      description => "Given a name (case sensitive, concatenated by dashes), redirect if there is a single match.  The first and last names can be in either order.",
  },
  organization_contributors => {
      brief => "Show contributions made by an organizations",
      description => "Given a role (contributor, author, etc.) and a resource type (e.g. platform, dataset, report), list contributions made by the organization of that type.",
  },
  person_contributions => {
      brief => "Show contributions of a certain type by a person",
      description => "Given a resource (dataset, report, etc.) and a role ('editor', etc'), and an identifier for a person, show the resources to which the person has contributed in that role."
  },
  organization_contributions => {
      brief => "Show contributions of a certain type by an organization",
      description => "Given a resource (dataset, report, etc.) and a role ('editor', etc'), and an identifier for an organization, show the resources to which the organization has contributed in that role."
  },
  find_term => {
      brief => "Lookup a GCID from a term",
      description => "Given a lexicon, term, and context, return a 303 redirect to a GCID",
  },
  show_exterm => {
      brief => "Lookup a GCID from a term",
      description => "Given a lexicon, term, and context, return a 303 redirect to a GCID",
  },
  lexicon_terms => {
      brief => "List the terms within a context of a lexicon",
      description => "List the terms within a context of a lexicon",
  },
  metrics => {
      brief => "Get overall metrics about GCIS data",
      description => "Get overall metrics about GCIS data",
  },

);

sub find_doc {
    my $c = shift;
    my $route_name = shift;
    my $entry = $RouteDoc{$route_name} or return;
    return Tuba::RouteDoc->new(
      name        => $route_name,
      brief       => $entry->{brief},
      description => $entry->{description},
      params      => [map Tuba::RouteParam->new(%$_), @{$entry->{params}}],
      note        => $entry->{note},
      tags        => $entry->{tags},
    );
}

sub _common_list_params {
   my $what = shift;
   my %a = @_;

   return (
          ($a{not_all} ? () : (
          {
            name => "all",
            type => "boolean",
            description => "Set to 1 to get all of the $what.",
          })),
          {
            name => "page",
            type => "integer",
            description => "The page number (starting at 1).",
          });
}

sub _common_list_note {
    my $what = shift;
    return qq[Examine the 'Content-Range' header to determine the number of pages.];
}

sub _list_defaults {
    my $what = shift;
    my %a = @_;
    my $plural = $what.'s';
    $plural = "activities" if $what eq 'activity';
    $plural = "people" if $what eq 'person';
    my $phrase = $plural;
    if (my $add = $a{add}) {
        $phrase = "$plural $add";
    }
    return (
        brief  => "List $phrase.",
        note   => _common_list_note(),
        params => [ _common_list_params($plural, %a) ],
        description => "List the $phrase, 20 per page.",
    );
}

sub _show_defaults {
    my $what = shift;
    my %a = @_;
    my $an = "a";
    $an = "an" if $what =~ /^[aeiou]/;
    my $phrase = $what;
    $phrase .= " $a{add}" if $a{add};
    return (
      brief =>  "Get a representation of $an $phrase.",
      description => "Get JSON which represents the structure of $an $phrase.",
      $a{withs} ? 
      (
          params => [
            { name => "with_regions", type => "boolean", description => "Include regions associated with the $what." },
            { name => "with_gcmd",    type => "boolean", description => "Include GCMD keywords associated with the $what." },
          ]
      ) : ()
      )
}
 
sub _route_to_path {
  my $s = shift;
  my $route = shift;
  my $p = $route->parent or return '/';
  my @p;
  while ($p) {
    unshift @p, $p;
    $p = $p->parent;
  }
  my $str = "";
  my @params;
  for my $q (@p, $route) {
    for my $piece (@{ $q->pattern->tree }) {
        my $as_str = (!ref $piece                ? $piece
            : $piece->[0] eq 'slash'       ? '/'
            : $piece->[0] eq 'text'        ? $piece->[1]
            : $piece->[0] eq 'placeholder' ? '{'.$piece->[1].'}'
            : $piece->[0] eq 'wildcard'    ? '{'.$piece->[1].'}'
            : $piece->[0] eq 'relaxed'     ? '{'.$piece->[1].'}'
            : 'other');
        $str .= $as_str;
        push @params,
          {
              name     => $piece->[1],
              in       => "path",
              required => \1,
              type => "string",
              description => "$piece->[1] description",
          }
          if $piece->[0] =~ /placeholder|wildcard|relaxed/;
    }
  }
  return $str unless @params;
  return ( $str, \@params );
}

sub _walk_routes {
    my $s = shift;
    my $c = shift;
    my ($route, $depth) = @_;
    if ($route->is_endpoint) {
        my ($path,$params) = $s->_route_to_path($route);
        my $doc = $s->find_doc($route->name) || Tuba::RouteDoc->new;
        return unless $path;
        my @via = @{ $route->via };
        my $name = $route->name;
        die "more than 1: @via " if @via > 1;
        my $method = $via[0];
        return (
              $path => {
                  'method'    => lc $method,
                  ( summary     => $doc->brief ) x !!$doc->brief,
                  description => $doc->description // do {
                      # warn "missing description for $name\n";
                      "missing"; },
                  responses   => {200 => { description => "ok" } },
                  produces    => [ "application/json" ],
                  tags        => $doc->tags || [ "other" ],
                  ( parameters  => $params ) x !!$params,
              }
        );
    }
    return map $s->_walk_routes($c, $_, $depth + 1), @{ $route->children };
}

sub _build_paths {
    my $s = shift;
    my $c = shift;
    #     Example from http://swagger.io/specification/#pathsObject
    #     {
    #       "/pets": {
    #         "get": {
    #           "description": "Returns all pets from the system that the user has access to",
    #           "produces": [
    #             "application/json"
    #           ],
    #           "responses": {
    #             "200": {
    #               "description": "A list of pets.",
    #               "schema": {
    #                 "type": "array",
    #                 "items": {
    #                   "$ref": "#/definitions/pet"
    #                 }
    #               }
    #             }
    #           }
    #         }
    #       }
    #     }
    my @routes = $s->_walk_routes($c, $c->app->routes, 0);
    # Merge same path, different methods
    my %paths;
    while (@routes) {
        my $path = shift @routes;
        my $entry = shift @routes;
        $paths{$path}->{delete $entry->{method}} = $entry;
    }
    return \%paths;
}

sub as_swagger {
    my $s = shift;
    my $c = shift or die 'need controller';
    my $url = $c->req->url->clone->to_abs;
    my $host = $url->host;
    $host .= ":".$url->port if $url->port;

    return {
        swagger => "2.0",
        info => {
            title => "Global Change Information System",
            description => "The GCIS is an open-source, web-based resource for traceable, sound global change data, information, and products.",
            version => $Tuba::VERSION,
        },
    tags => [
            { name => "report", description => "Access report metadata." },
            { name => "figure", description => "Access metadata about figures in reports." },
            { name => "finding", description => "Access metadata about findings in reports." },
            { name => "table", description => "Access metadata about tables in reports." },
            { name => "dataset", description => "Query or update information related to datasets." },
            { name => "other", description => "Other routes" },
            { name => "reference", description => "Routes related to bibliographic information." },
        ],
        host => $host,
        paths => $s->_build_paths($c),
    };
}

1;
