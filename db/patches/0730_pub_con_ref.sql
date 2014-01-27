/* Add optional reference to publication_contributor_map,
indicating the a contributor is associated with a bibliographic
entry. */

alter table publication_contributor_map add column reference_identifier varchar;

alter table publication_contributor_map add constraint
    publication_contributor_map_reference
    foreign key (reference_identifier) references reference(identifier);

