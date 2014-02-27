alter table file add column thumbnail varchar;

update file set thumbnail=file where file not like '%.pdf';

alter table file drop column file_type, add column mime_type varchar;

update file set mime_type = 'image/jpeg' where file ilike '%.jpg';

update file set mime_type = 'image/png' where file ilike '%.png';

update file set mime_type = 'image/jpeg' where file ilike '%.jpeg';

update file set mime_type = 'image/gif' where file ilike '%.gif';

update file set mime_type = 'application/pdf' where file like '%.pdf';

delete from file where mime_type is null;

alter table file alter column mime_type set not null;

alter table file add column sha1 varchar;

