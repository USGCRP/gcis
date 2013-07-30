alter table file
    drop constraint file_ibfk_1,
    add constraint file_image foreign key (image)
        references image(identifier) on delete cascade;


