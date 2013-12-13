alter table image_figure_map
    drop constraint image_figure_map_image_fkey,
    add constraint image_figure_map_image_fkey
        foreign key (image_identifier) references image(identifier)
        on delete cascade on update cascade;

