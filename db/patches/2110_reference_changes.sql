insert into subpubref (reference_identifier, publication_id)
    select identifier, publication_id from reference;

alter table reference drop column publication_id;

