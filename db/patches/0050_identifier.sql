
delete from file;
alter table file drop column image_id;
alter table image drop column id;
alter table image add column identifier varchar not null primary key;
alter table file add column image varchar references image(identifier);

delete from image;
alter table image drop column figure_id;
alter table figure drop column id;
alter table figure add column identifier varchar not null primary key;
alter table image add column figure varchar references figure(identifier);
alter table figure drop column uuid;

delete from chapter;
alter table figure drop column chapter_id;
alter table chapter drop column id;
alter table chapter drop column short_name;
alter table chapter add column identifier varchar not null primary key;
alter table figure add column chapter varchar references chapter(identifier);

delete from report;
alter table chapter drop column report_id;
alter table report drop column short_name;
alter table report drop column id;
alter table report add column identifier varchar not null primary key;
alter table chapter add column report varchar references report(identifier);


