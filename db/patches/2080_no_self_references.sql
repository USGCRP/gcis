alter table reference add constraint no_self_references
 check (child_publication_id != publication_id);

