ALTER TABLE gcis_metadata.organization_alternate_name
DROP CONSTRAINT organization_alternate_name_organization_identifier_fkey,
ADD CONSTRAINT organization_alternate_name_organization_identifier_fkey
   FOREIGN KEY (organization_identifier)
   REFERENCES organization(identifier)
   ON UPDATE CASCADE
   ON DELETE CASCADE;
