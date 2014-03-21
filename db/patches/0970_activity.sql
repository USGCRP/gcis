update activity set identifier = lower(translate(identifier,' ','-'))
   where identifier not similar to '[a-z0-9_-]+';

alter table activity add constraint ck_activity_identifier
    check (identifier similar to '[a-z0-9_-]+');

