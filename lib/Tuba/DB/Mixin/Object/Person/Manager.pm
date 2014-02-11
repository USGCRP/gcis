package Tuba::DB::Object::Person::Manager;
# Tuba::DB::Mixin::Person::Manager

sub _make_query {
    my $s = shift;
    my ($str) = @_;
    my @q = $s->SUPER::_make_query(@_);
    $str =~ s/'//g;
    push @q, \qq[first_name || ' ' || last_name ilike '%$str%'];
    return @q;
}

1;

