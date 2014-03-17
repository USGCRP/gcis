alter table figure add unique (report_identifier, chapter_identifier, ordinal);
alter table finding add unique (report_identifier, chapter_identifier, ordinal);
alter table "table" add unique (report_identifier, chapter_identifier, ordinal);

