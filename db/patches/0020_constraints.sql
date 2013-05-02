alter table chapter drop column report_id;

alter table chapter add column report_id integer references report(id);

