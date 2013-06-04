#!/usr/bin/env perl

=head1 NAME

Tuba -- Tremendously Useful Backend API

=head1 DESCRIPTION

Tuba provides a RESTful API to GCIS data.

=cut

package Tuba;
use Mojo::Base qw/Mojolicious/;

our $VERSION = '0.11';

sub demo {
 my $c = shift;
 my $path = $c->req->url->path;
 $c->respond_to(
            json => sub { shift->render_json({demo => 'data', 'you_requested' => $path }) },
            html => sub { shift->render({text => "<html>demo data, you requested <b>$path</b></html>", format => 'html'}) },
            any  => sub {  my $c = shift; $c->render_text('request type is not supported'.$c->req->headers->to_string) },
        )
};

sub startup {
    my $app = shift;

    $app->secret('aePhoox5Iegh6toeay3ooV9n');
    $app->plugin('InstallablePaths');

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
    }) if $app->mode eq 'production';

    # Shortcuts (see Mojolicious::Guides::Routing)
    $app->routes->add_shortcut(resource => sub {
      my ($r, $name) = @_;
      my $resource = $r->route("/$name")->to("$name#");
      $resource->post->to('#create')->name("create_$name");
      $resource->get->to('#list')->name("list_$name");
      my $identifier = join '_', $name, 'identifier';
      $identifier =~ s/-/_/g;
      $resource->get(":$identifier")->to('#show')->name("show_$name");
      $resource->bridge(":$identifier")->to(cb => sub { 1; } )->name("select_$name");
      return $resource;
    });

    my $r = $app->routes;

    # API
    $r->resource('report');
    $r->lookup('select_report')->resource('chapter');
    $r->lookup('select_report')->resource('figure');
    $r->lookup('select_report')->resource('key-message');
    $r->lookup('select_report')->resource('traceable-account');
    $r->resource('publication');
    $r->resource($_) for qw/article journal paper/;
    $r->resource('image');
    $r->lookup('select_image')->post( '/setmet' )->to('#setmet')->name('image_setmet');
    $r->lookup('select_image')->get( '/checkmet')->to('#checkmet')->name('image_checkmet');
    $r->resource($_) for qw/dataset model software algorithm activity
                            instrument platform
                            person role organization country/;
    $r->resource("file");

    # Tuba-specific routes
    $r->get('/' => sub {
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
    } => 'index');

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

