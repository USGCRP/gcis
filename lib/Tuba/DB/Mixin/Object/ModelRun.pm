package Tuba::DB::Object::ModelRun;
# Tuba::DB::Mixin::Object::ModelRun;
use Tuba::Util qw[new_uuid];

__PACKAGE__->meta->primary_key_generator(sub {
    return new_uuid();
});

1;

