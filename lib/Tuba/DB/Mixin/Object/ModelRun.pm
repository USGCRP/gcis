package Tuba::DB::Object::ModelRun;
# Tuba::DB::Mixin::Object::ModelRun;
use Data::UUID::LibUUID;

__PACKAGE__->meta->primary_key_generator(sub {
    return new_uuid_string(4);
});

1;

