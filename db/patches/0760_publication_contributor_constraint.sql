alter table publication_contributor_map add constraint
    publication_contributor_map_reference_publication
    foreign key (reference_identifier, publication_id)
    references reference(identifier, child_publication_id)
    on delete cascade on update cascade;

alter table publication_contributor_map drop constraint 
    publication_contributor_map_reference;
