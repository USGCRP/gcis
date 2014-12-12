alter table report add column curation_note varchar;
alter table report add column curation_email varchar;
comment on column report.curation_note is 'A note about the curation of this report.  Brackets in this note are phrases for [contacting the curator].';
comment on column report.curation_email is 'A contact email address for the curator of this report.';

