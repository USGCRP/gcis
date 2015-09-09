alter table role_type add column comment varchar;

comment on column role_type."comment" is 'A description of this role.';

