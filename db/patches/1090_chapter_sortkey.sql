alter table chapter add column sort_key integer;

update chapter set sort_key = number * 10 where number is not null;

