
CREATE TABLE organization_alternate_name (
    organization_identifier varchar REFERENCES organization(identifier) ON DELETE cascade,
    alternate_name text NOT NULL,
    language varchar(3) NOT NULL CONSTRAINT iso_lang_length CHECK (char_length(language) >= 2),
    deprecated boolean NOT NULL DEFAULT false,
    PRIMARY KEY (organization_identifier, alternate_name)
);

COMMENT ON TABLE organization_alternate_name IS 'Alternate names for organizations either multilingual or defunct';

COMMENT ON COLUMN organization_alternate_name.organization_identifier IS 'The organization identifier this name belongs to.';
COMMENT ON COLUMN organization_alternate_name.alternate_name IS 'The alternate name of the organization.';
COMMENT ON COLUMN organization_alternate_name.language IS 'The language used for this alternate name. Format ISO-639-1, fallback ISO-639-2T';
COMMENT ON COLUMN organization_alternate_name.deprecated IS 'If the name is historical and no longer used. Default False';

COMMENT ON COLUMN organization.name IS 'The organization as referred to in English.';
