
drop table if exists _report_viewer;
create table _report_viewer (
    report varchar references report(identifier),
    username varchar not null,
    primary key (report,username)
);

drop table if exists _report_editor;
create table _report_editor (
    report varchar references report(identifier),
    username varchar not null,
    primary key (report,username)
);

