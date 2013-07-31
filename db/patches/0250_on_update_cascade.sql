alter table image_figure_map
    drop constraint image_figure_map_figure_fkey,
     add constraint image_figure_map_figure_fkey foreign key (figure,report)
        references figure(identifier,report) on delete cascade on update cascade;

