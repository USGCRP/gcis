insert into organization_type (identifier) select 'ngo'        where not exists(select 1 from organization_type where identifier='ngo');
insert into organization_type (identifier) select 'federal'    where not exists(select 1 from organization_type where identifier='federal');
insert into organization_type (identifier) select 'municipal'  where not exists(select 1 from organization_type where identifier='municipal');
insert into organization_type (identifier) select 'state'      where not exists(select 1 from organization_type where identifier='state');
insert into organization_type (identifier) select 'research'   where not exists(select 1 from organization_type where identifier='research');
insert into organization_type (identifier) select 'commercial' where not exists(select 1 from organization_type where identifier='commercial');
insert into organization_type (identifier) select 'private'    where not exists(select 1 from organization_type where identifier='private');
insert into organization_type (identifier) select 'academic'   where not exists(select 1 from organization_type where identifier='academic');
