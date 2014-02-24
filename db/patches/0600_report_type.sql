create table report_type (identifier varchar not null primary key);

insert into report_type (identifier) values ('report'),('assessment'),('scenario');

alter table report add column report_type_identifier varchar references report_type(identifier);

