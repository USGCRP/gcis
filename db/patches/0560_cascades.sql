
    ALTER TABLE ONLY figure
    drop CONSTRAINT figure_chapter_report,
    ADD CONSTRAINT figure_chapter_report FOREIGN KEY (chapter_identifier, report_identifier) REFERENCES chapter(identifier, report_identifier)
        on delete cascade on update cascade;


    ALTER TABLE ONLY figure
    drop CONSTRAINT figure_report_fkey,
    ADD CONSTRAINT figure_report_fkey FOREIGN KEY (report_identifier) REFERENCES report(identifier)
        on delete cascade on update cascade;


    ALTER TABLE ONLY "table"
    drop CONSTRAINT table_chapter_identifier_fkey,
    ADD CONSTRAINT table_chapter_identifier_fkey FOREIGN KEY (chapter_identifier, report_identifier) REFERENCES chapter(identifier, report_identifier)
    on delete cascade
    on update cascade;

    ALTER TABLE ONLY "table"
    drop CONSTRAINT table_report_identifier_fkey,
    ADD CONSTRAINT table_report_identifier_fkey FOREIGN KEY (report_identifier) REFERENCES report(identifier)
    on delete cascade
    on update cascade;

    drop trigger updatepub on "table";

    create trigger updatepub
         before update on "table"
     for each row when ( NEW.identifier != OLD.identifier OR new.report_identifier <> old.report_identifier::text ) execute procedure update_publication();

