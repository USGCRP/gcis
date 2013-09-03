
\t on
\! rm -f /tmp/runme.sql
\o /tmp/runme.sql
select 
'update publication_file_map set file = '||
(array_agg(identifier))[1]
||' where file in '
|| '(' || array_to_string(array_agg(identifier),',') || ');'
from file f
inner join publication_file_map m on m.file=f.identifier
group by f.file
having count(1) > 1;
\o

\i /tmp/runme.sql

delete from file where identifier in (
select f.identifier from file f left join publication_file_map m
on m.file=f.identifier where m.file is null
);

alter table file add unique(file);

alter table file alter column file set not null;

