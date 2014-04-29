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
      brief  => "Get a list of reports.",
      description => "List the reports, 20 per page.",
      note   => _common_list_note(),
      params => [ _common_list_params('reports') ],
  },
  list_chapter => { _list_defaults('chapter'), brief => "List chapters in a report", description => "Get a list of chapters in a report." },
  list_finding => { _list_defaults('finding'), brief => "List findings in a chapter", description => "Get a list of findings in a chapter." },
  list_figure  => { _list_defaults('figure'), brief => "List figures in a chapter", description => "Get a list of figures in a chapter." },
  list_table   => { _list_defaults('table'), brief => "List tables in a chapter", description => "Get a list of tables in a chapter." },
  list_chapter_references => { _list_defaults('reference'), brief => "List references in a chapter", description => "Get a list of references in a chapter." },
  list_all_findings => { _list_defaults('finding', add => "in a report") },
  list_all_figures => { _list_defaults('figure', add => "in a report") },
  list_all_tables => { _list_defaults('table', add => "in a report") },
  list_report_references => { _list_defaults('reference', add => "in a report") },

  image => { _list_defaults('image', add => 'associated with a report') },
  array => { _list_defaults('array', add => 'associated with a report') },
  webpage => { _list_defaults('webpage', add => 'associated with a report') },
  image => { _list_defaults('image', add => 'associated with a report') },
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
  list_gcmd_keyword => { _list_defaults('GCMD keyword', add => "in the GCIS", not_all => 1) },
  list_reference => { _list_defaults('reference', not_all => 1) },
  list_generic => { _list_defaults('generic publication' ) },

  show_report => { _show_defaults('report', withs => 1) },
  show_chapter => { _show_defaults('chapter', withs => 1) },
  show_figure => { _show_defaults('figure', withs => 1) },
  show_finding => { _show_defaults('finding', withs => 1) },
  show_table => { _show_defaults('table', withs => 1) },
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

);

sub find_doc {
    my $c = shift;
    my $route_name = shift;
    my $entry = $RouteDoc{$route_name} or return;
    return Tuba::RouteDoc->new(
        name => $route_name,
        brief => $entry->{brief},
        description => $entry->{description},
        params => [ map Tuba::RouteParam->new( %$_ ), @{ $entry->{params} } ],
        note => $entry->{note},
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
    return (
      brief =>  "Get a representation of $an $what.",
      description => "Get JSON which represents the structure of $an $what.",
      $a{withs} ? 
      (
          params => [
            { name => "with_regions", type => "boolean", description => "Include regions associated with the $what." },
            { name => "with_gcmd",    type => "boolean", description => "Include GCMD keywords associated with the $what." },
          ]
      ) : ()
      )
}
 
1;
