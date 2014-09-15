package Tuba::DB::Object::ConventionManager;

use parent 'Rose::DB::Object::ConventionManager';

sub singular_to_plural {
    my $s = shift;
    my $word = shift;
    return 'arrays' if $word eq 'array';
    return $s->SUPER::singular_to_plural($word);
}

sub tables_are_singular {
    1;
}

sub is_map_class {
    my $s = shift;
    my $class = shift;
    return 1 if $class =~ /InstrumentInstance/;
    return $s->SUPER::is_map_class($class);
}

1;
