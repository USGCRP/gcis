alter table figure add column url varchar;
alter table finding add column url varchar;
alter table "table" add column url varchar;

comment on column figure.url is 'A URL for a landing page for this figure.';
comment on column finding.url is 'A URL for a landing page for this finding.';
comment on column "table".url is 'A URL for a landing page for this table.';

