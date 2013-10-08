alter table publication_file_map drop constraint publication_file_map_file_fkey;

alter table file alter column identifier type varchar using identifier::varchar;

alter table publication_file_map alter column file_identifier type varchar using file_identifier::varchar;

alter table publication_file_map add foreign key( file_identifier) references file(identifier) on delete cascade on update cascade;



