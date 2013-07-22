
/* drop a few primary keys */
alter table chapter drop constraint chapter_pkey cascade; /* cascades to figure and finding */
alter table figure  drop constraint figure_pkey cascade;  /* cascades to image_figure_map */
alter table finding drop constraint finding_pkey cascade; /* cascades to finding_keyword_map */

/* add report everywhere */
/* chapter, finding okay */
alter table figure add column report varchar not null default 'nca3draft' references report(identifier);
alter table image_figure_map add column report varchar not null default 'nca3draft' references report(identifier);
alter table finding_keyword_map add column report varchar not null default 'nca3draft' references report(identifier);

/* add primary key report+chapter */
alter table chapter add primary key (identifier, report);

/* add foreign keys referencing the above */
alter table figure add constraint figure_chapter_report
    foreign key (chapter,report) references chapter (identifier,report);
alter table finding add constraint finding_chapter_report
    foreign key (chapter,report) references chapter (identifier,report);

/* add primary keys */
alter table figure add constraint figure_pkey primary key (identifier, report);
alter table finding add constraint finding_pkey primary key (identifier, report);

/* Now fix up ancillary tables too */
alter table image_figure_map
    add foreign key (figure,report) references figure(identifier,report)
    on delete cascade;
alter table finding_keyword_map
    add foreign key (finding,report) references finding(identifier,report)
    on delete cascade;
alter table finding_keyword_map
    drop constraint finding_keyword_map_pkey,
    add constraint finding_keyword_map_pkey
    primary key (finding,keyword,report);
alter table image_figure_map
    drop constraint image_figure_map_pkey,
    add constraint image_figure_map_pkey
    primary key (image,figure,report);

/* redundant relationships */
alter table finding_keyword_map drop constraint finding_keyword_map_report_fkey;
alter table image_figure_map drop constraint image_figure_map_report_fkey;

/* remove defaults */
alter table figure              alter column report drop default;
alter table image_figure_map    alter column report drop default;
alter table finding_keyword_map alter column report drop default;


