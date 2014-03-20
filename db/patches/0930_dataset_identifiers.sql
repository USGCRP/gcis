update dataset set identifier = lower(translate(identifier,' ''()','----'))
   where identifier not similar to '[a-z0-9_-]+';

alter table dataset add constraint ck_dataset_identifier
    check (identifier similar to '[a-z0-9_-]+');

