
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

create table "worksheet" (
    identifier varchar not null primary key,
    labels varchar[],
    rows varchar[][]
);

create table worksheet_table_map (
    worksheet_identifier varchar references worksheet(identifier) not null,
    table_identifier varchar not null,
    report_identifier varchar not null,
    foreign key (table_identifier,report_identifier) references
        "table" (identifier, report_identifier )
)

create trigger delpub before delete on "table" for each row execute procedure delete_publication();
create trigger updatepub before update on "table" for each row when ( NEW.identifier != OLD.identifier ) execute procedure update_publication();

create trigger delpub before delete on "worksheet" for each row execute procedure delete_publication();
create trigger updatepub before update on "worksheet" for each row when ( NEW.identifier != OLD.identifier ) execute procedure update_publication();

select audit.audit_table('table');
select audit.audit_table('worksheet');
select audit.audit_table('worksheet_table_map');

