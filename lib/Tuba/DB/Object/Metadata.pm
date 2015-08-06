package Tuba::DB::Object::Metadata;

use base 'Rose::DB::Object::Metadata';

__PACKAGE__->column_type_class( issn => 'Tuba::DB::Object::Metadata::Column::ISSN' );

1;
