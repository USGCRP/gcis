alter table array_table_map drop constraint array_table_map_array_identifier_fkey,
    add constraint array_table_map_array_identifier_fkey foreign key (array_identifier)
        references "array"(identifier) on update cascade on delete cascade;

alter table array_table_map drop constraint array_table_map_table_identifier_fkey,
    add constraint array_table_map_table_identifier_fkey foreign key (table_identifier, report_identifier)
        references "table"(identifier, report_identifier) on update cascade on delete cascade;

