alter table finding drop constraint finding_report_fkey,
add constraint finding_report_fkey foreign key (report_identifier) references report(identifier) on delete cascade on update cascade;

