update dataset set doi = replace(doi,'doi:','');
comment on column article.doi is 'The digital object identifier for the article.';
alter table dataset add constraint dataset_doi_check check (doi ~ '^10.[[:print:]]+/[[:print:]]+$');
alter table report add constraint report_doi_check check (doi ~ '^10.[[:print:]]+/[[:print:]]+$');
alter table report add constraint report_doi_unique unique(doi);

