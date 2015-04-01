alter table "array" add constraint array_dimensions check( array_ndims(rows) = 2 );

