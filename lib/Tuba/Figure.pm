=head1 NAME

Tuba::Figure : Controller class for figures.

=cut

package Tuba::Figure;
use Mojo::Base qw/Tuba::Controller/;
use Tuba::DB::Objects qw/-nicknames/;
use Tuba::Log qw/logger/;

sub list {
    my $c = shift;
    $c->param(thumbs => 1) unless defined($c->param('thumbs')) && length($c->param('thumbs'));
    my $figures;
    my $all = $c->param('all');
    my @page = $all ? () : (page => $c->page, per_page => $c->per_page);
    if (my $ch = $c->stash('chapter')) {
        my $report_identifier = $c->stash('report_identifier');
        $figures = Figures->get_objects(
            query => [chapter_identifier => $ch->identifier, report_identifier => $report_identifier], with_objects => ['chapter'],
            @page,
            sort_by => "number, ordinal, t1.identifier",
            );
        $c->set_pages(Figures->get_objects_count(
            query => [chapter_identifier => $ch->identifier, report_identifier => $report_identifier], with_objects => ['chapter'],
            )) unless $all;
    } elsif (my $report_identifier = $c->stash('report_identifier')) {
        $figures = Figures->get_objects(
           with_objects => ['chapter'], sort_by => "number, ordinal, t1.identifier",
           query => [ report_identifier => $report_identifier ],
           @page,
       );
       $c->set_pages(Figures->get_objects_count(
           query => [ report_identifier => $report_identifier ])
       ) unless $all;
    } else {
        $figures = Figures->get_objects(
           with_objects => ['report', 'chapter'], sort_by => "number, ordinal, t1.identifier",
           @page,
       );
       $c->set_pages(Figures->get_objects_count()) unless $all;
    }
    $c->stash(objects => $figures);
    $c->SUPER::list(@_);
}

sub set_title {
    my $c = shift;
    if (my $ch = $c->stash('chapter')) {
        $c->stash(title => sprintf("Figures in chapter %s of %s",$ch->stringify(tiny => 1), $ch->report->title));
    } elsif (my $report = $c->stash('report')) {
        $c->stash(title => sprintf("Figures in %s",$c->stash('report')->title));
    } else {
        $c->stash(title => "All figures");
    }
}

sub show_origination {
    my $c = shift;
    my $identifier = $c->stash('figure_identifier');
    my $object = Figure->new(
      identifier        => $identifier,
      report_identifier => $c->stash('report_identifier')
      )->load(speculative => 1);

    if (!$object && $identifier =~ /^[0-9]+[0-9a-zA-Z._-]*$/ && $c->stash('chapter') ) {
        my $chapter = $c->stash('chapter');
        $object = Figure->new(
          report_identifier  => $c->stash('report_identifier'),
          chapter_identifier => $chapter->identifier,
          ordinal            => $identifier,
        )->load(speculative => 1);
    };
    return $c->render_not_found_or_redirect unless $object;

    my $origination = $object->get_origination();
    $c->respond_to(
        json => sub { my $c = shift;
            $c->render(text => $origination, format => 'json' ); },
    );
}

sub update_origination {
    my $c = shift;
    my $identifier = $c->stash('figure_identifier');

    logger->warn("YO! I made it to the post function");

    my $figure = $c->_this_object or return $c->reply->not_found;

    my $json = $c->req->json;
    if ( ! $json ) {
       return $c->render(json => { success => 0, error => "invalid JSON" } );
    }
    my $json_string = $c->req->text;

    #$figure->{_origination} = $json_string;

    $c->render(json => $json_string );
}

sub show {
    my $c = shift;
    my $identifier = $c->stash('figure_identifier');
    my $object = Figure->new(
      identifier        => $identifier,
      report_identifier => $c->stash('report_identifier')
      )->load(speculative => 1, with => [qw/chapter images/]);

    if (!$object && $identifier =~ /^[0-9]+[0-9a-zA-Z._-]*$/ && $c->stash('chapter') ) {
        my $chapter = $c->stash('chapter');
        $object = Figure->new(
          report_identifier  => $c->stash('report_identifier'),
          chapter_identifier => $chapter->identifier,
          ordinal            => $identifier,
        )->load(speculative => 1, with => [qw/chapter images/]);
        return $c->redirect_to($object->uri_with_format($c)) if $object;
    };
    return $c->render_not_found_or_redirect unless $object;

    if (!$c->stash('chapter_identifier') && $object->chapter_identifier) {
        $c->stash(chapter_identifier => $object->chapter_identifier);
    }
    return $c->reply->not_found unless $c->verify_consistent_chapter($object);

    $c->stash(object => $object);
    $c->stash(meta => Figure->meta);
    $c->SUPER::show(@_);
}

sub update_form {
    my $c = shift;
    my $object = $c->_this_object or return $c->reply->not_found;
    $c->verify_consistent_chapter($object) or return $c->reply->not_found;
    $c->SUPER::update_form(@_);
}

sub update_rel_form {
    my $c = shift;
    $c->stash(relationships => [ map Figure->meta->relationship($_), qw/images/ ]);
    $c->stash(controls => {
            images => sub {
                my ($c,$obj) = @_;
                +{
                    template => 'image',
                    params => { }
                  }
              }
        });
    $c->SUPER::update_rel_form(@_);
}

sub update_rel {
    my $c = shift;
    my $object = $c->_this_object or return $c->reply->not_found;
    $c->stash(tab => "update_rel_form");
    my $json = $c->req->json;

    $object->meta->error_mode('return');

    if (my $new = $c->param('new_image')) {
        my $img = $c->Tuba::Search::autocomplete_str_to_object($new);
        $object->add_images($img);
        $object->save(audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->update_error($object->error);
    }
    if (my $new = $json->{add_image_identifier}) {
        my $img = Image->new(identifier => $new)->load(speculative => 1)
            or return $c->update_error("Image $new not found");
        $object->add_images($img);
        $object->save(audit_user => $c->audit_user, audit_note => $c->audit_note) or return $c->update_error($object->error);
    }

    my $report_identifier = $c->stash('report_identifier');
    my @delete_images = $c->param('delete_image');
    if (my $nother = $json->{delete_image_identifier}) {
        push @delete_images, $nother;
    }
    for my $id (@delete_images) {
        ImageFigureMaps->delete_objects({ image_identifier => $id, figure_identifier => $object->identifier, report_identifier => $report_identifier });
        $c->flash(message => 'Saved changes');
    }

    return $c->SUPER::update_rel(@_);
}

1;

