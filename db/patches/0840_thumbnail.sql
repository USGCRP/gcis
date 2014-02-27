alter table file add column thumbnail varchar;

update file set thumbnail=file where file not like '%.pdf';

