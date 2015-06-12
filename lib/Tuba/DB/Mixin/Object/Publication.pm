package Tuba::DB::Object::Publication;
# Tuba::DB::Mixin::Object::Publication;

use Pg::hstore qw/hstore_decode/;
use Tuba::Log;
use File::Temp;
use Path::Class qw/file/;
use Mojo::ByteStream qw/b/;
use List::Util qw/reduce/;
use strict;

sub stringify {
    my $self = shift;
    my %args = @_;
    my $label;
    if (my $obj = $self->to_object) {
        $label = $obj->stringify(%args);
    } else {
        $label = join '/', map $self->$_, $self->meta->primary_key_column_names;
    }
    for ($self->publication_type_identifier) {
        /report/ and return $label;
        /article/ and return $label;
        /book/ and return $label;
        /^(image|book)$/ and $args{tiny} and return $label;
    }
    return $label if $args{long};
    return $self->publication_type_identifier.' '.$label;
}

sub to_object {
    my $self = shift;
    my %a = @_;
    my $orm = Tuba::DB::Objects->table2class;
    my $type = $self->publication_type or die "no type for ".$self->id;
    my $obj_class = $orm->{$type->table}->{obj} or return;
    my @pkcols = $obj_class->meta->primary_key_columns;
    my $pkvals = hstore_decode($self->fk);
    my $obj = $obj_class->new(%$pkvals);
    if (eval { $obj->load(speculative => 1) }) {
        return $obj;
    }
    logger->warn("Error loading publication ".$self->id." -- ".$self->fk);
    logger->warn("Error : $@") if $@;

    if ($a{autoclean}) {
        logger->warn("autoclean : removing orphan publication ".$self->id);
        $self->delete;
    } else {
        logger->warn("not cleaning up");
    }
    return;
}

sub children {
    my $self = shift;

    my $got = Tuba::DB::Object::PublicationMap::Manager->get_objects(
        query => [ parent => $self->id ],
        limit => 100,
    );
    return wantarray ? @$got : $got;
}

sub get_parents {
    # Get objects which are parents of this one.
    # Returns an array of hashrefs : { relationship => 'foo', publication => $pub_object }
    my $self = shift;
    my $class = ref($self) || $self;
    my $dbh = $self->db->dbh;
    my $sth = $dbh->prepare(<<'SQL');
select p.*, m.relationship, m.note, m.activity_identifier from publication p
    inner join publication_map m on m.parent=p.id
    where m.child = ?
SQL
    $sth->execute($self->id) or die $dbh->errstr;
    my $rows = $sth->fetchall_arrayref({});
    my @parents;
    for my $row (@$rows) {
        my %pub;
        @pub{qw/id publication_type_identifier fk/} = @$row{qw/id publication_type_identifier fk/};
        my %rec  = (
              relationship => $row->{relationship},
              note         => $row->{note},
              publication  => $class->new(%pub)
        );
        if (my $id = $row->{activity_identifier}) {
              $rec{activity} = Tuba::DB::Object::Activity->new(identifier => $id)->load();
        };
        push @parents, \%rec;
    };
    return @parents;
}

sub get_parents_with_references {
    my $s = shift;
    my %args = @_;
    # uniq => 1
    #    will avoid duplicate publications (which can occur if multiple references
    #    references refer to the same publication)
    # for_export => 1
    #     will return data structures rather than objects.
    # c => $controller
    #     necessary for for_export
    my $c = $args{c};
    die "need controller for export" if $args{for_export} && !$c;

    my $first = <<SQL;
    select
        subp.publication_type_identifier,
        s.publication_id                    as parent_publication_id,
        r.child_publication_id              as child_publication_id,
        r.identifier                        as reference_identifier
      from reference r
        inner join publication_reference_map s      on s.reference_identifier = r.identifier
        inner join publication subp on s.publication_id = subp.id
      where r.child_publication_id  = ?
SQL
    my $dbs = DBIx::Simple->new($s->db->dbh);

    my @results = $dbs->query($first, $s->id)->hashes;
    my %uniq;
    @results = grep !$uniq{$_->{parent_publication_id}}{$_->{child_publication_id}}++, @results if $args{uniq};
    if ($args{for_export} && $c) {
        my @serialized;
        for (@results) {
            my $parent = (ref $s)->new(id => $_->{parent_publication_id})->load->to_object;
            my $record = { reference => "/reference/$_->{reference_identifier}",
                           relationship => "cito:isCitedBy",
                           uri => $parent->uri($c) };
            push @serialized, $record;
        }
        return @serialized;
    }
    for (@results) {
        $_->{parent} = (ref $s)->new(id => $_->{parent_publication_id})->load;
        $_->{child} = (ref $s)->new(id => $_->{child_publication_id})->load;
        $_->{reference} = Tuba::DB::Object::Reference->new(identifier => $_->{reference_identifier});
    }
    return @results;
}

sub get_children_with_references {
    my $s = shift;
    my %a = @_;
    my $limit = $a{limit} || 5000;
    $limit = 1 unless $limit =~ /^[0-9]+$/;
    $limit = 5000 if $limit > 5000;

    my $first = <<SQL;
    select
        subp.publication_type_identifier,
        s.publication_id                    as parent_publication_id,
        r.child_publication_id              as child_publication_id,
        r.identifier                        as reference_identifier
      from reference r
        inner join publication_reference_map s on s.reference_identifier = r.identifier
        inner join publication subp on s.publication_id = subp.id
      where s.publication_id  = ?
      limit $limit
SQL
    my $dbs = DBIx::Simple->new($s->db->dbh);

    my @results = $dbs->query($first, $s->id)->hashes;
    @results = @results[0..$limit-1] if @results > $limit;
    for (@results) {
        $_->{parent} = $s;
        $_->{child} = (ref $s)->new(id => $_->{child_publication_id})->load if $_->{child_publication_id};
        $_->{reference} = Tuba::DB::Object::Reference->new(identifier => $_->{reference_identifier});
    }
    return @results;
}

=head2 upload_file

Add a Mojo::Upload object to this publication.
Returns the new Tuba::DB::Object::File on success or false on failure.  
$type is an optional content type (file suffix takes precedence).
, in case the file has no suffix indica.

=cut

sub upload_file {
    my $pub = shift;
    my %args = @_;
    my ($c,$upload,$type) = @args{qw/c upload type/};
    my $file = $upload;
    unless ($file && $file->size) {
        $pub->error("Missing or empty file.");
        return;
    }

    my $image_dir = $c->config('image_upload_dir') or do { logger->error("no image_upload_dir configured"); die "configuration error"; };
    -d $image_dir or do { logger->error("no such dir : $image_dir"); die "configuration error"; };

    my $md5 = b($file->slurp)->md5_sum;
    my $md5_dir = join '/', substr($md5,0,2), substr($md5,2,2), substr($md5,4);

    if ($type) {
        if ($type =~ m[image/jpeg]) {
            $file->filename( $file->filename.'.jpg') unless $file->filename =~ /\.jpe?g$/i;
        }
    }
    my $filename = $file->filename;
    $filename =~ s/ /_/g;
    $filename =~ tr[a-zA-Z0-9_.-][]dc;
    my $name = join '/', $md5_dir, $filename;
    my $f = file("$image_dir/$name");
    $f->dir->mkpath;
    $file->move_to("$f") or die $!;
    my $tfile = Tuba::DB::Object::File->new(file => $name);
    $tfile->set_sha1 or do {
        $pub->error("Could compute sha1");
        return;
    };
    $tfile->checkfix_mime_type($type) or do {
        $pub->error("Could not determine mime type from filename $filename.  Supported suffixes are : ".join ',', $tfile->supported_suffixes);
        return;
    };
    $tfile->size($file->size);
    $pub->add_files($tfile);
    $pub->save(audit_user => $c->user);
    $tfile->meta->error_mode('return');
    $tfile->save(audit_user => $c->user) or do {
        $pub->error($tfile->error);
        return;
    };

    $tfile->load;
    return $tfile;
}

sub uri {
    my $s = shift;
    my $c = shift;
    my $opts = shift;
    my $route_name = $opts->{tab} || 'show';
    $route_name .= '_publication';

    return $c->url_for($route_name) unless ref($s);
    return $c->url_for($route_name, { publication_identifier => $s->id } );
}

sub contributors_grouped {
    my $object = shift;
    my @cons = @{ Tuba::DB::Object::Contributor::Manager->get_objects(
        query => [ publication_id => $object->id ],
        with_objects => [ qw/publication_contributor_maps role_type/ ],
        sort_by => [ qw/role_type.sort_key role_type.identifier t2.sort_key person_id/]
    ) };

    my $role_count;
    my $person_count;
    for (@cons) {
      $role_count->{$_->role_type_identifier}++;
      $person_count->{$_->role_type_identifier}{$_->person_id}++;
    }
    return (\@cons, $role_count, $person_count);
}

sub _cons_with_role {
    my $pub = shift;
    my $role = shift;
    my $cons = shift;
    my %seen;
    my @out;
    for my $con (@$cons) {
        next unless $con->role_type_identifier eq $role->identifier;
        next if $con->person_id && $seen{$con->person_id}++;
        if ($con->person_id) {
            push @out, +{
                person => $con->person,
                orgs => [ map $_->organization, grep { $_->person_id == $con->person_id
                                                        and $_->role_type_identifier eq $con->role_type_identifier
                                                     } @$cons
                ],
            };
            next;
        }
        push @out, +{ person => undef, orgs => [ $con->organization ] };
    }
    return \@out;
}

sub contributors_nested {
    my $object = shift;
    my @cons = @{ Tuba::DB::Object::Contributor::Manager->get_objects(
        query => [ publication_id => $object->id ],
        with_objects => [ qw/publication_contributor_maps role_type/ ],
        sort_by => [ qw/role_type.sort_key role_type.identifier t2.sort_key person_id/]
    ) };

    my @nested;
    my %seen;
    for my $row (@cons) {
        next if $seen{$row->role_type_identifier}++;
        push @nested, { role => $row->role_type, people => $object->_cons_with_role($row->role_type, \@cons) };
    }
    return \@nested;
}

sub contributors_having_role {
    my $object = shift;
    my $role_type_identifier = shift or die 'missing role';
    my @cons = @{ Tuba::DB::Object::Contributor::Manager->get_objects(
        query => [ publication_id => $object->id, role_type_identifier => $role_type_identifier ],
        with_objects => [ qw/publication_contributor_maps/ ],
    ) };
    return wantarray ? @cons : \@cons;
}


sub references_url {
    # If there is a URL to list the references, it goes here.
    my $pub = shift;
    my $c = shift;
    for ($pub->publication_type_identifier) {
        /chapter/ and do {
            my $chapter = $pub->to_object;
            my $url = $c->url_for(
              'list_chapter_references',
              {
                report_identifier  => $chapter->report->identifier,
                chapter_identifier => $chapter->identifier
              }
            );
            return $url;
        };
        /report/ and do {
            return $c->url_for('list_report_references', { report_identifier => $pub->to_object->identifier} );
        };
    }
    return;
}

sub largest_file {
    my $p = shift;
    my $found = reduce { $a->size > $b->size ? $a : $b } $p->files;
    return unless $found;
    return $found;
}

sub smallest_file {
    my $p = shift;
    my $found = reduce { $a->size < $b->size ? $a : $b } $p->files;
    return unless $found;
    return $found;
}

sub references {
    my $s = shift;
    # default 'references' generated by rose would use child_publication_id from reference table; i.e.
    # things referencing this publication.
    return Tuba::DB::Object::Reference::Manager->get_objects(with_objects => 'publications', query => [publication_id => $s->id]);
}

1;

