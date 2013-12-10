update journal set print_issn=NULL where print_issn='-';
update journal set print_issn=NULL where print_issn='0002-9637';
delete from journal where identifier='JAWWA';
update journal set online_issn=NULL where online_issn='-';
delete from journal where identifier='TCD';

alter table journal add constraint uk_journal_print_issn unique (print_issn);
alter table journal add constraint uk_journal_online_issn unique (online_issn);

alter table article alter column journal_identifier set not null;

