alter table file add column id serial;
update file set id = cast(identifier as integer);
alter table file drop column identifier;
alter table file rename column id to identifier;
alter table file add primary key(identifier);

