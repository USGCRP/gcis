update organization set identifier = replace(identifier,'(','_') where identifier not similar to '[a-z0-9_-]+';

update organization set identifier = replace(identifier,'–','-') where identifier not similar to '[a-z0-9_-]+';

update organization set identifier = replace(identifier,'&','-') where identifier not similar to '[a-z0-9_-]+';

alter table organization add constraint
    organization_identifier_check
    CHECK (identifier similar to '[a-z0-9_-]+');

