
update report set report_type_identifier='report' where report_type_identifier is null;

alter table report alter column report_type_identifier set not null;

alter table report alter column report_type_identifier set default 'report';


