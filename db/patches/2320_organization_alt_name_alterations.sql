ALTER TABLE organization_alternate_name
    ADD COLUMN identifier SERIAL;
ALTER TABLE organization_alternate_name
    DROP CONSTRAINT organization_alternate_name_pkey;
ALTER TABLE organization_alternate_name
    ADD PRIMARY KEY (identifier);
ALTER TABLE organization_alternate_name
    ADD UNIQUE (organization_identifier, alternate_name);


COMMENT ON COLUMN organization_alternate_name.identifier IS 'An automatically-generated unique numeric identifier.';
