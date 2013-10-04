
alter table publication_map
    add column reference_identifier varchar
    references reference(identifier)
    on delete cascade
    on update cascade;

create table generic (identifier varchar not null primary key, attrs hstore);

insert into publication_type (identifier, "table") values ('generic', 'generic');

create trigger delpub before delete on generic for each row execute procedure delete_publication();

create trigger updatepub before update on generic for each row when ( NEW.identifier != OLD.identifier ) execute procedure update_publication();

alter table publication_map add unique(reference_identifier);

