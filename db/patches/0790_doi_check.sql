delete from article where doi !~ '^10.[[:print:]]+/[[:print:]]+$';

delete from article where not (identifier similar to '[a-z0-9_-]+' or identifier ~ '^10.[[:print:]]+/[[:print:]]+$');

alter table article add constraint article_doi_check check (doi ~ '^10.[[:print:]]+/[[:print:]]+$');

update article set identifier=doi where not (identifier = doi or identifier similar to '[a-z0-9_-]+');

alter table article add constraint article_identifier_check check (identifier similar to '[a-z0-9_-]+' or identifier ~ '^10.[[:print:]]+/[[:print:]]+$');

