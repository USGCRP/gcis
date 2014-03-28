alter table file add column location varchar;

update report set url = 'http://' || url where url like 'www%';

update report set url = 'http://' || url where url like 'info%';

update report set url = 'http://' || url where url like 'water%';

update file f
    set location  = substring(r.url from '((https?|ftp)://[^/]+)'),
        file      = regexp_replace(r.url, '((https?|ftp)://[^/]+)',''),
        mime_type = 'application/pdf'
    from report r
        inner join publication p on (p.fk->'identifier' = r.identifier and p.publication_type_identifier = 'report')
        inner join publication_file_map m on m.publication_id = p.id
    where r.url like '%pdf'
        and f.location is null
        and f.identifier = m.file_identifier;

