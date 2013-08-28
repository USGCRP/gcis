delete from publication where fk is null;
alter table publication alter column fk set not null;

