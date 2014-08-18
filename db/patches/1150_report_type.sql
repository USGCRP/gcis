
update report set report_type_identifier='report' where report_type_identifier is null;

alter table report alter column report_type_identifier set not null;

alter table report alter column report_type_identifier set default 'report';

insert into report_type (identifier)
select 'report' where not exists (select identifier from report_type where identifier = 'report');


