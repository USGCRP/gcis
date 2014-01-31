alter table reference
    drop constraint reference_child_publication_id_fkey,
    add constraint reference_child_publication_id_fkey
    FOREIGN KEY (child_publication_id) REFERENCES publication(id) ON DELETE SET NULL;

