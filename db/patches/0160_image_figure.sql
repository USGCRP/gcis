create table image_figure_map (
    image varchar references image(identifier) on delete cascade,
    figure varchar references figure(identifier) on delete cascade,
    primary key (image,figure)
);

alter table image drop column figure;

