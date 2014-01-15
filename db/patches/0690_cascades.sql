alter table finding
    drop constraint finding_chapter_report,
    add constraint finding_chapter_fkey foreign key (chapter_identifier, report_identifier)
        references chapter(identifier, report_identifier)
        on update cascade on delete cascade;

