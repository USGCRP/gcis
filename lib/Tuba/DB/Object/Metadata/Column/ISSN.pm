package Tuba::DB::Object::Metadata::Column::ISSN;

use base 'Rose::DB::Object::Metadata::Column::Varchar';

sub length {
    return 9;
}

sub type {
    return "issn";
}

1;
