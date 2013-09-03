alter table article drop constraint article_ibfk_1,
    add constraint article_ibfk_1 foreign key (journal) 
        references journal(identifier) on delete cascade on update cascade;

update journal set title = 'BioScience' where title = ' BioScience';
update journal set identifier=title where identifier='';

