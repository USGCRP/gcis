create table book (
    identifier varchar not null primary key,
    title varchar not null,
    isbn varchar unique,
    year numeric,
    publisher varchar,
    number_of_pages numeric,
    url varchar
);

select audit.audit_table('book');

create trigger delpub before delete on book for each row execute procedure delete_publication();

create trigger updatepub before update on book for each row when (new.identifier::text <> old.identifier::text) execute procedure update_publication();

insert into publication_type (identifier,"table")
    values ('book','book');

