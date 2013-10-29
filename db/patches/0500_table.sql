drop table if exists "array" cascade;
drop table if exists "table" cascade;
drop table if exists "array_table_map" cascade;

create table "table" (
    identifier varchar not null,
    report_identifier varchar references report(identifier),
    chapter_identifier varchar,
    ordinal integer,
    title varchar,
    caption varchar,
    primary key (identifier, report_identifier),
    foreign key (chapter_identifier, report_identifier) references
        chapter (identifier, report_identifier)
);

create table "array" (
    identifier varchar not null primary key,
    rows_in_header integer default 0,
    rows varchar[][]
);

create table array_table_map (
    array_identifier varchar references "array"(identifier) not null,
    table_identifier varchar not null,
    report_identifier varchar not null,
    primary key (array_identifier, table_identifier, report_identifier),
    foreign key (table_identifier,report_identifier) references
        "table" (identifier, report_identifier )
);


create trigger delpub before delete on "table" for each row execute procedure delete_publication();
create trigger updatepub before update on "table" for each row when ( NEW.identifier != OLD.identifier ) execute procedure update_publication();

create trigger delpub before delete on "array" for each row execute procedure delete_publication();
create trigger updatepub before update on "array" for each row when ( NEW.identifier != OLD.identifier ) execute procedure update_publication();

select audit.audit_table('table'::regclass);
select audit.audit_table('array'::regclass);
select audit.audit_table('array_table_map');

insert into publication_type (identifier,"table") values ('array','array');
insert into publication_type (identifier,"table") values ('table','table');

