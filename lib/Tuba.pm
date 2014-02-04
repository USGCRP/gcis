#!/usr/bin/env perl

=head1 NAME

Tuba -- Tremendously Useful Backend API

=head1 DESCRIPTION

Tuba provides a RESTful API to GCIS data.

=cut

package Tuba;
use Mojo::Base qw/Mojolicious/;
use Mojo::ByteStream qw/b/;
use Tuba::Converter;
use Tuba::Log;
use Data::UUID::LibUUID;

our $VERSION = '0.61';
our @supported_formats = qw/json yaml ttl html nt rdfxml dot rdfjson jsontriples svg/;

sub startup {
    my $app = shift;

    $app->plugin('InstallablePaths');

    Tuba::Log->set_logger($app->log);

    $ENV{MOJO_MAX_MESSAGE_SIZE} = 52428800;

    # Plugins, configuration
    my $conf =
        $ENV{TUBA_CONFIG}             ? $ENV{TUBA_CONFIG}
      : -f '/usr/local/etc/Tuba.conf' ? '/usr/local/etc/Tuba.conf'
      :                                 './Tuba.conf';
    $app->plugin( 'yaml_config' => { file => $conf } );
    unshift @{$app->plugins->namespaces}, 'Tuba::Plugin';
    $app->plugin( 'db', ( $app->config('database') || die "no database config" ) );
    if (my $path = $app->config('log_path')) {
        $app->log->info("logging to $path");
        $app->log(Mojo::Log->new(path => $path));
    }
    $app->plugin('Auth' => $app->config('auth'));
    $app->plugin('TubaHelpers' => { supported_formats => \@supported_formats });

    # Hooks
    $app->hook(after_dispatch => sub {
        my $c = shift;
        $c->res->headers->header('Access-Control-Allow-Origin' => '*');
        $c->res->headers->header('X-API-Version' => $Tuba::VERSION );
    } );
    $app->hook(before_dispatch => sub {
        # Remove path when behind a proxy (see Mojolicious::Guides::Cookbook).
        my $c = shift;
        push @{$c->req->url->base->path}, shift @{$c->req->url->path}
          if @{ $c->req->url->path->parts } && $c->req->url->path->parts->[0] eq 'api';
        my $forward_base = $c->req->headers->header('X-Forwarded-Base');
        $c->req->url->base(Mojo::URL->new($forward_base)) if $forward_base;
    }) if $app->mode eq 'production';

    # Shortcuts (see Mojolicious::Guides::Routing)
    # For a given resource we create several routes.  As an
    # example, for the resource 'report' we create :
    #    name           method, path, controller
    #    -----------   --------------------------
    #    list_report        : GET /report                    calls Tuba::Report::list
    #    show_report        : GET /report/:report_identifier calls Tuba;:Report::show
    #  * create_report      : POST /report                   calls Tuba::Report::create
    #  * create_form_report : GET /report/form/create        calls Tuba::Report::create_form
    #  * update_form_report : GET /report/:report_identifier/form/update calls Tuba::Report::update_form
    #  * update_report      : POST /report/:report_identifier/ calls Tuba::Report::update
    #
    #    Also we create and return a route named 'select_report'.  This can be used to
    #    attach other resources lower in the URL path hierarchy.
    #
    #  * Require authentication.
    #
    $app->routes->add_condition(
        not_match => sub {
            my ($route, $c, $captures, $args) = @_;
            for my $k (keys %$args) {
                return undef if $captures->{$k} =~ m{$args->{$k}};
            }
            return 1;
        }
    );
    $app->routes->add_shortcut(resource => sub {
      my ($r, $name, $opts) = @_;
      #
      # $opts is a hash which can have :
      #    restrict_identifier -- a regex for the identifier pattern
      #    wildcard -- means the identifier could have a /
      #    defaults -- default values for routes for this resource.
      #    controller -- controller class
      #    identifier -- name of the stash key for the identifier (tablename + '_identifier')
      #    path_base -- initial path for urls (/tablename)
      #
      my $identifier = $opts->{identifier} || join '_', $name, 'identifier';
      my $controller = $opts->{controller} || 'Tuba::'.b($name)->camelize;
      my $path_base = $opts->{path_base} || $name;

      eval " use $controller ";
      if ($@) {
          unless ($@ =~ /^Can't locate/) {
              warn "loading $controller failed ---------- $@\n";
              die $@;
          }
          # $app->log->debug("did not load $controller");
      }
      my $cname = $controller;
      $cname =~ s/Tuba:://;
      $cname = lc $cname;

      # Build bridges and routes.
      my $resource = $r->route("$path_base")->to("$cname#");
      $resource->get->to('#list')->name("list_$name");
      my $select;
      my @restrict = $opts->{restrict_identifier} ? ( $identifier => $opts->{restrict_identifier} ) : ();
      my %defaults = $opts->{defaults} ? %{ $opts->{defaults} } : ();
      if ($opts->{wildcard}) {
        my $reserved = qr[^(?:form/update
                                (?:_prov|_rel|_files|_contributors)?
                             |form/create
                             |update
                                (?:_prov|_rel|_files|_contributors)?
                             |put_files
                             |history
                           )
                         ]x;
        for my $format (@supported_formats) {
                $resource->get("*$identifier.$format" => \@restrict => { format => $format } )
                         ->over(not_match => { $identifier => $reserved })
                         ->to('#show')->name("_show_${name}_$format");
        }
        $resource->get("*$identifier" => \@restrict => \%defaults )->over(not_match => { $identifier => $reserved })->to('#show')->name("show_$name");
      } else {
        $resource->get(":$identifier" => \@restrict => \%defaults )->to('#show')->name("show_$name");
        $select = $resource->bridge(":$identifier")->to('#select')->name("select_$name");
      }

      my $authed = $r->bridge("/$path_base")->to(cb => sub {
              my $c = shift;
              $c->auth && $c->authz(role => 'update') }
      )->name("authed_select_$name");
      $authed->post->to("$cname#create")->name("create_$name");
      $authed->get('/form/create')->to("$cname#create_form")->name("create_form_$name");

      if ($opts->{wildcard}) {
          $authed->get("/form/update/*$identifier" => \%defaults)      ->to("$cname#update_form")->name("update_form_$name");
          $authed->get("/form/update_prov/*$identifier" => \%defaults) ->to("$cname#update_prov_form")->name("update_prov_form_$name");
          $authed->get("/form/update_rel/*$identifier" => \%defaults)  ->to("$cname#update_rel_form")->name("update_rel_form_$name");
          $authed->get("/form/update_keywords/*$identifier" => \%defaults)  ->to("$cname#update_keywords_form")->name("update_keywords_form_$name");
          $authed->get("/form/update_files/*$identifier" => \%defaults)->to("$cname#update_files_form")->name("update_files_form_$name");
          $authed->get("/form/update_contributors/*$identifier" => \%defaults)->to("$cname#update_contributors_form")->name("update_contributors_form_$name");
          $authed->get("/history/*$identifier" => \%defaults)          ->to("$cname#history")    ->name("history_$name");
          $authed->delete("*$identifier" => \%defaults)                ->to("$cname#remove")     ->name("remove_$name");
          $authed->post("*$identifier" => \%defaults)->over(not_match => { $identifier => qr[^(?:prov|rel|files)/] })
                                                   ->to("$cname#update")     ->name("update_$name");
          $authed->post("/prov/*$identifier")      ->to("$cname#update_prov")->name("update_prov_$name");
          $authed->post("/rel/*$identifier")       ->to("$cname#update_rel")->name("update_rel_$name");
          $authed->post("/keywords/*$identifier")       ->to("$cname#update_keywords")->name("update_keywords_$name");
          $authed->post("/files/*$identifier")     ->to("$cname#update_files")->name("update_files_$name");
          $authed->post("/contributors/*$identifier")     ->to("$cname#update_contributors")->name("update_contributors_$name");
          $authed->put("/files/*$identifier/#filename") # a default filename for PUTs would be ambiguous.
                                                   ->to("$cname#put_files")->name("put_files_$name");
      } else {
          $authed->get("/form/update/:$identifier")                    ->to("$cname#update_form")->name("update_form_$name");
          $authed->get("/form/update_prov/:$identifier" => \%defaults) ->to("$cname#update_prov_form")->name("update_prov_form_$name");
          $authed->get("/form/update_rel/:$identifier" => \%defaults)  ->to("$cname#update_rel_form")->name("update_rel_form_$name");
          $authed->get("/form/update_keywords/:$identifier" => \%defaults)  ->to("$cname#update_keywords_form")->name("update_keywords_form_$name");
          $authed->get("/form/update_files/:$identifier" => \%defaults)->to("$cname#update_files_form")->name("update_files_form_$name");
          $authed->get("/form/update_contributors/:$identifier" => \%defaults)->to("$cname#update_contributors_form")->name("update_contributors_form_$name");
          $authed->get("/history/:$identifier" => \%defaults)    ->to("$cname#history")    ->name("history_$name");
          $authed->delete(":$identifier" => \%defaults)          ->to("$cname#remove")     ->name("remove_$name");
          $authed->post(":$identifier" => \%defaults)            ->to("$cname#update")     ->name("update_$name");
          $authed->post("/prov/:$identifier" => \%defaults)      ->to("$cname#update_prov")->name("update_prov_$name");
          $authed->post("/rel/:$identifier" => \%defaults)       ->to("$cname#update_rel")->name("update_rel_$name");
          $authed->post("/keywords/:$identifier" => \%defaults)       ->to("$cname#update_keywords")->name("update_keywords_$name");
          $authed->post("/files/:$identifier" => \%defaults)     ->to("$cname#update_files")->name("update_files_$name");
          $authed->post("/contributors/:$identifier" => \%defaults)     ->to("$cname#update_contributors")->name("update_contributors_$name");
          $authed->put("/files/:$identifier/#filename" => {filename => 'unnamed', %defaults })
                                                   ->to("$cname#put_files")->name("put_files_$name");
      }

      return $select;
    });

    my $r = $app->routes;

    # API
    $r->get(
      '/uuid' => sub {
        my $c = shift;
        my $count = $c->param('count') || 1;
        $count = 1 unless $count =~ /^[0-9]+$/;
        return $c->render( text => "sorry, max is 1000 at once" ) if $count > 1000;
        $c->res->headers->content_type('text/plain');
        $c->render(
          text => join "\n", (map new_uuid_string(4), 1..$count)
        );
      } => 'uuid'
    );

    #
    # Various resources, each one gets GET, POST, forms, and other routes.
    # (see the resource helper for more details).
    #

    # Reports.
    my $report = $r->resource('report');

    # Chapters.
    my $chapter = $report->resource('chapter');
    $r->lookup('select_chapter')->resource('finding');
    $r->lookup('select_chapter')->resource('figure');
    $r->lookup('select_chapter')->resource('table');
    $r->lookup('select_chapter')->get('/reference')->to('reference#list')->name('list_chapter_references');

    # Report (finding|figure|table)s have no chapter.
    $report->get('/finding')->to('finding#list')->name('list_all_findings');
    $report->get('/figure') ->to('figure#list') ->name('list_all_figures');
    $report->get('/table')  ->to('table#list')  ->name('list_all_tables');
    $report->get('/reference')->to('reference#list')->name('list_report_references');
    $report->resource('report_finding', { controller => 'Tuba::Finding', identifier => 'finding_identifier', path_base => 'finding' });
    $report->resource('report_figure',  { controller => 'Tuba::Figure',  identifier => 'figure_identifier',  path_base => 'figure' });
    $report->resource('report_table',   { controller => 'Tuba::Table',   identifier => 'table_identifier',   path_base => 'table' });

    # Redirect from chapter numbers to names.
    $r->get('/report/:report_identifier/chapter/:chapter_number/figure/:figure_number'
        => [ chapter_number => qr/\d+/, figure_number => qr/\d+/ ]
      )->to('figure#redirect_to_identifier')->name('figure_redirect');
    $r->get('/report/:report_identifier/chapter/:chapter_number/table/:table_number'
        => [ chapter_number => qr/\d+/, table_number => qr/\d+/ ]
      )->to('table#redirect_to_identifier')->name('table_redirect');

    # Redirect from generics to specifics.
    $r->get('/publication/:publication_identifier')->to('publication#show')->name('show_publication'); # redirect based on type.
    $r->get('/contributor/:contributor_identifier')->to('contributor#show')->name('show_contributor'); # redirect based on type.

    # Article (which have DOIs so slashes are allowed in the URL)
    $r->resource(article => { wildcard => 1} );

    # Journals, papers.
    $r->resource($_) for qw/journal paper/;

    # Images (globally unique)
    $r->resource('image');
    $report->get('/image')->to('image#list');

    # array (globally unique)
    $r->resource('array');
    $report->get('/array')->to('array#list');

    # webpage (globally unique)
    $r->resource('webpage');
    $report->get('/webpage')->to('webpage#list');

    # book (globally unique)
    $r->resource('book');
    $report->get('/book')->to('book#list');

    # Metadata processing routes.
    #$r->lookup('select_image')->post( '/setmet' )->to('#setmet')->name('image_setmet');
    #$r->lookup('select_image')->get( '/checkmet')->to('#checkmet')->name('image_checkmet');

    # Person.
    $r->resource(person => { restrict_identifier => qr/\d+/ } );
    $r->get('/person/:orcid' => [orcid => qr(\d{4}-\d{4}-\d{4}-\d{4})])
      ->to('person#redirect_by_orcid');
    $r->get('/person/:name')->to('person#redirect_by_name');

    $r->resource('organization');
    $r->post('/organization/lookup/name')->to('organization#lookup_name');
    $r->post('/person/lookup/name')->to('person#lookup_name');
    $r->lookup('select_organization')->post('/merge')->to('organization#merge')->name('merge_organization');

    # GcmdKeyword
    $r->resource('gcmd_keyword');

    # Others, some of which aren't yet implemented.
    $r->resource($_) for qw/dataset model software algorithm activity
                            instrument platform
                            role country/;

    # Files.
    $r->resource("file");

    # Bibliographic entry.
    my $reference = $r->resource('reference');
    $report->get('/reference')->to('reference#list');
    $r->lookup('authed_select_reference')->post('/match')->to('reference#smartmatch');
    $r->bridge('/reference/match')
      ->to(cb => sub {
              my $c = shift;
              $c->auth && $c->authz(role => 'update')
        })
      ->post('/:reference_identifier')
      ->to('reference#smartmatch');
    $r->get("/reference/lookup/:record_number" => [ record_number => qr/\d+/])->to('reference#lookup');
    $r->get('/reference/report/updates')->to('reference#updates_report')->name('reference_updates_report');

    # Generic publication.
    $r->resource('generic');

    # Search route.
    $r->get('/search')->to('search#keyword')->name('search');

    # To regenerate the owl file, get this URL :
    # http://ontorule-project.eu/parrot?documentUri=http://orion.tw.rpi.edu/~xgmatwc/ontology-doc/GCISOntology.ttl
    # Then prefix href's for the css at the top with
    #   http://ontorule-project.eu/parrot
    $app->types->type(owl => 'text/html');

    # Tuba-specific routes
    $r->get('/')->to('controller#index')->name('index');
    $r->get('/api_reference' => sub {
      my $c = shift;
      my $trying; if (my $try = $c->param('try')) {
          $trying = $c->app->routes->lookup($try);
      }
      $c->stash(trying => $trying);
      return unless $trying;
      my @placeholders;
      while ($trying) {
          for my $n (@{ $trying->pattern->tree }) {
              next unless @$n==2;
              next unless $n->[0] =~ /^(placeholder|wildcard|relaxed)$/;
              unshift @placeholders, $n->[1];
          }
          $trying = $trying->parent;
      }
      $c->stash(placeholders => \@placeholders);
    } => 'api_reference');

    $r->get('/resources')->to('doc#resources')->name('resources');
    $r->get('/examples')->to('doc#examples')->name('examples');
    $r->get('/autocomplete')->to('search#autocomplete');

    my $authed = $r->bridge->to(cb => sub { my $c = shift; $c->auth && $c->authz(role => 'update')});
    $authed->get('/admin')->to(cb => sub { shift->render })->name('admin');
    $authed->get('/watch')->to('report#watch')->name('_watch');
    $r->get('/login')->to('auth#login')->name('login');
    $r->get('/login_pw')->to('auth#login_pw')->name('_login_pw');
    $r->get('/login_key')->to('auth#login_key')->name('_login_key');

    $r->post('/login')->to('auth#check_login')->name('check_login');
    $r->get('/oauth2callback')->to('auth#oauth2callback')->name('_oauth2callback');
    $r->get('/logout')->to(cb => sub { my $c = shift; $c->session(expires => 1); $c->redirect_to('index') });

    $authed->get('/import_form')->to('importer#form')->name('import_form');
    $authed->post('/process_import')->to('importer#process_import')->name('process_import');

    $r->post('/calculate_url' => sub {
        my $c = shift;
        my $for = $c->param('_route_name');
        my $route = $c->app->routes->lookup($for) or return $c->render_not_found;
        my $params = $c->req->params->to_hash;
        delete $params->{_route_name};
        my $got = $c->url_for($for, $params);
        $c->render(json => { path => $got->path });
    } => 'calculate_url');

    $app->routes->get('/debug') if $ENV{TUBA_DEBUG};
    $app->routes->get('/open-search')->name('opensearch');
    unless ($app->mode eq 'production') {
        $app->routes->get('/sparql' => sub {
                my $c = shift;
                my $url = $c->req->url->clone;
                $url->host('gcis-dev-front.joss.ucar.edu');
                $c->redirect_to($url);
            });
    }
}

1;

