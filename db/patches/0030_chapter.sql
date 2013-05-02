alter table chapter add column number integer;
alter table chapter drop column short_name;
alter table chapter add column short_name varchar not null unique;

