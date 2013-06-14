#!/usr/bin/env perl

=head1 NAME

Tuba -- Tremendously Useful Backend API

=head1 DESCRIPTION

Tuba provides a RESTful API to GCIS data.

=cut

package Tuba;
use Mojo::Base qw/Mojolicious/;
use Mojo::ByteStream qw/b/;
use Time::Duration qw/ago/;
use Date::Parse qw/str2time/;

our $VERSION = '0.24';

sub startup {
    my $app = shift;

    $app->secret('aePhoox5Iegh6toeay3ooV9n');
    $app->plugin('InstallablePaths');
    $app->defaults->{report_identifier} = "nca3";

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
    $app->plugin('Auth');

    # Helpers
    $app->helper(base => sub {
        my $c = shift;
        my $base = $c->url_for('index')->path;
        $base =~ s[/$][];
        return $base;
    } );
    $app->helper(obj_link => sub {
            my $c = shift;
            my $obj = shift;
            return "" unless defined($obj);
            my $val = $obj->stringify;
            my $uri = $obj->uri($c);
            return $val unless $uri;
            return $c->link_to($val, $uri );
        } );
    $app->helper(format_ago => sub {
            my $c = shift;
            my $date = shift;
            return ago(time - str2time($date));
        });

    # Hooks
    $app->hook(after_dispatch => sub {
        my $c = shift;
        $c->res->headers->header('Access-Control-Allow-Origin' => '*');
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
    my @forms;
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
    $app->routes->add_shortcut(resource => sub {
      my ($r, $name) = @_;

      # Keep stubs out of @forms.
      my $controller = 'Tuba::'.b($name)->camelize;
      eval " use $controller ";
      if (!$@) {
         push @forms, "create_form_$name";
      } else {
          die $@ unless $@ =~ /^Can't locate/;
          # $app->log->debug("did not load $controller");
      }

      # Build bridges and routes.
      my $resource = $r->route("/$name")->to("$name#");
      my $authed = $r->bridge("/$name")->to(cb => sub { shift->auth });
      $authed->post->to("$name#create")->name("create_$name");
      $authed->get('/form/create')->to("$name#create_form")->name("create_form_$name");
      $resource->get->to('#list')->name("list_$name");
      my $identifier = join '_', $name, 'identifier';
      $identifier =~ s/-/_/g;
      $resource->get(":$identifier")->to('#show')->name("show_$name");
      $authed->get(":$identifier/form/update")->to("$name#update_form")->name("update_form_$name");
      $authed->post(":$identifier")->to("$name#update")->name("update_$name");
      $authed->get(":$identifier/history")->to("$name#history")->name("history_$name");
      $authed->delete(":$identifier")->to("$name#remove")->name("remove_$name");
      my $select = $resource->bridge(":$identifier")->to(cb => sub { 1; } )->name("select_$name");
      return $select;
    });

    my $r = $app->routes;

    # API
    my $report = $r->resource('report');
    $report->resource('chapter');
    $report->resource('figure');
    $report->resource('key-message');
    $report->resource('traceable-account');
    $report->resource('finding');
    $r->resource('publication');
    $r->resource($_) for qw/article journal paper/;
    $r->resource('image');
    $r->get('/article/doi/*doi')->to('article#doi');
    $r->lookup('select_image')->post( '/setmet' )->to('#setmet')->name('image_setmet');
    $r->lookup('select_image')->get( '/checkmet')->to('#checkmet')->name('image_checkmet');
    $r->resource($_) for qw/dataset model software algorithm activity
                            instrument platform
                            person role organization country/;
    $r->resource("file");

    # Redirects
    $r->get('/report/:report_identifier/chapter/:chapter_number/figure/:figure_number'
        => [ chapter_number => qr/\d+/, figure_number => qr/\d+/ ]
      )->to('figure#redirect_to_identifier')->name('figure_redirect');

    # Tuba-specific routes
    $r->get('/')->to('controller#index')->name('index');
    $r->get('/reference' => sub {
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
    } => 'reference');
    $r->get('/resources' => 'resources');
    $r->get('/examples' => 'examples');

    $r->get('/forms')->to(cb => sub { shift->render(forms => \@forms) })->name('forms');
    $r->get('/login')->to('auth#login')->name('login');
    $r->post('/login')->to('auth#check_login')->name('check_login');
    $r->get('/logout')->to(cb => sub { my $c = shift; $c->session(expires => 1); $c->redirect_to('index') });

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
}

1;

