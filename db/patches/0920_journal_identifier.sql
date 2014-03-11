update journal set identifier = 'missing' where identifier='';
alter table journal add constraint ck_journal_identifier check (identifier similar to '[a-z0-9_-]+');

