package Tuba::DB::Object::Toolkit::Manager;
#Tuba::DB::Mixin::Object::Toolkit::Manager

use strict;
use warnings;

sub dbgrep {
    my $self = shift;
    my %a = @_;

    my $per_page = $a{per_page} || $a{limit} || 10;  #previously implemented as a limit;
    my $query_string = $a{query_string} or return;
    chomp $query_string;
    $query_string =~ s/^\s+//;
    $query_string =~ s/\s+$//;

    my @query = $self->_make_query($query_string) or return;
    my $found;
    if ($a{count_only}) {
        my $count = $self->get_objects_count( distinct => 1,
                                              select => 'gcid',
                                              query => [ or => \@query ],
                                              #debug => 1,
                                            );
        #bless the hash, so that rendering works (mostly) the same as full-fledged results
        my @count = $count ? (bless { results_count => $count } , $self->object_class ) : ();
        $found = \@count;
    } else {
        $found = $self->get_objects( distinct => 1,
                                     select => 'gcid, description',
                                     query => [ or => \@query ],
                                     $a{all} ? () : (page => $a{page}, per_page => $per_page),
                                     #debug => 1,  #dump raw SQL to stderr (in morbo output, not devel log)
                                   );
    }
    return @$found;
}

1;

