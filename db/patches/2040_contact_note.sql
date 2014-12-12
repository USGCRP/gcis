alter table report add column contact_note varchar;
alter table report add column contact_email varchar;
comment on column report.contact_note is 'A note about contacting someone about this report.  Brackets in this note are phrases for [making contact].';
comment on column report.contact_email is 'A contact email address for this report.';

