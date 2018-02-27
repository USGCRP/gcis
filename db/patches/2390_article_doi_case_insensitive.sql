CREATE UNIQUE INDEX article_doi_uniq_index
ON gcis_metadata.article
(lower(doi));
