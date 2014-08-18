alter table instrument_instance add constraint instrument_platform_map_platform
    foreign key (platform_identifier)
    references platform on update cascade on delete cascade;

