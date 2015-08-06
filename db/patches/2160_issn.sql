create extension isn;

/* data fixes for dev instances */

update journal set print_issn  = '2040-2244' where print_issn = '2010-2244';
update journal set online_issn = '545-7885X' where online_issn = '545-7885';
update journal set online_issn = '0975-9174' where online_issn='0975–9174';

alter table journal add column new_print_issn issn unique;
alter table journal add column new_online_issn issn unique;

update journal set new_print_issn = print_issn::issn;

update journal set new_online_issn = trim(online_issn)::issn;

alter table journal drop column print_issn;

alter table journal drop column online_issn;

alter table journal rename column new_print_issn to print_issn;

alter table journal rename column new_online_issn to online_issn;

alter table journal add constraint has_issn check (print_issn is not null or online_issn is not null);

