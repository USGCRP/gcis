alter table report
    drop constraint report_organization_fkey,
    add constraint report_organization_fkey
        foreign key (organization) references organization(identifier)
            on update cascade;

alter table _report_viewer
    drop constraint _report_viewer_report_fkey,
    add constraint _report_viewer_report_fkey
        foreign key (report) references report(identifier)
            on update cascade on delete cascade;

alter table _report_editor
    drop constraint _report_editor_report_fkey,
    add constraint _report_editor_report_fkey
        foreign key (report) references report(identifier)
            on update cascade on delete cascade;

alter table chapter
    drop constraint chapter_ibfk_1,
    add constraint chapter_ibfk_1
        foreign key (report) references report(identifier)
            on update cascade on delete cascade;

