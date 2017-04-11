package Tuba::DB::Object::Metadata::Column::JSON;

use base 'Rose::DB::Object::Metadata::Column::Scalar';

sub type {
    return "json";
}

1;
