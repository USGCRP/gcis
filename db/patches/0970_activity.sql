update activity set identifier = lower(translate(identifier,' ','-'))
   where identifier not similar to '[a-z0-9_-]+';

alter table activity add constraint ck_activity_identifier
    check (identifier similar to '[a-z0-9_-]+');

select audit.audit_table('activity');

select audit.audit_table('methodology');

