
insert into publication_type (identifier,"table") select 'finding','finding'  where not exists(select 1 from publication_type where identifier='finding');
