
create table webpage (
    identifier varchar not null primary key,
    url varchar not null unique,
    title varchar,
    access_date timestamp
)

insert into publication_type (identifier,"table")
    values ('webpage','webpage');

select audit.audit_table('webpage');

create trigger delpub before delete on webpage for each row execute procedure delete_publication();

create trigger updatepub before update on webpage for each row when (new.identifier::text <> old.identifier::text) execute procedure update_publication();

