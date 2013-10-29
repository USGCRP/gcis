package Tuba::DB::Object::ConventionManager;

use parent 'Rose::DB::Object::ConventionManager';

sub singular_to_plural {
    my $s = shift;
    my $word = shift;
    return 'arrays' if $word eq 'array';
    return $s->SUPER::singular_to_plural($word);
}

# TODO
# table_are_singular

1;
