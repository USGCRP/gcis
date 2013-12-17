
alter table image add constraint ck_image_identifier check (identifier similar to '[a-z0-9_-]+');

update figure set identifier = lower(identifier) where identifier not similar to '[a-z0-9_-]+';

alter table figure add constraint ck_figure_identifier check (identifier similar to '[a-z0-9_-]+');

alter table "array" add constraint ck_array_identifier check (identifier similar to '[a-z0-9_-]+');

alter table book add constraint ck_book_identifier check (identifier similar to '[a-z0-9_-]+');

alter table chapter add constraint ck_chapter_identifier check (identifier similar to '[a-z0-9_-]+');

alter table file add constraint ck_file_identifier check (identifier similar to '[a-z0-9_-]+');

update finding set identifier = lower(identifier) where identifier not similar to '[a-z0-9_-]+';

update finding set identifier = 'agricultures-technical-ability-to-adapt' where identifier like 'agriculture%s-technical-%adapt';

alter table finding add constraint ck_finding_identifier check (identifier similar to '[a-z0-9_-]+');

alter table generic add constraint ck_generic_identifier check (identifier similar to '[a-z0-9_-]+');

alter table reference add constraint ck_reference_identifier check (identifier similar to '[a-z0-9_-]+');

alter table report add constraint ck_report_identifier check (identifier similar to '[a-z0-9_-]+');

alter table "table" add constraint ck_table_identifier check (identifier similar to '[a-z0-9_-]+');

alter table webpage add constraint ck_webpage_identifier check (identifier similar to '[a-z0-9_-]+');

delete from organization where identifier='col-for-res-uwash';

alter table organization add unique(name);

