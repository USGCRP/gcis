alter table file add column landing_page varchar;
comment on column file.landing_page is 'An optional URL associated with this file';

