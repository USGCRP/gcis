
                                             /* Sample values (comma separated) */

/* A project is a collection of experiments. */
drop table if exists project cascade;
create table project (
    identifier varchar not null primary key, /* cmip3, cmip4, cmip5 */
    name varchar,                            /* Coupled Model Intercomparison Project Phase 5 */
    description varchar,                     /* a paragraph from <http://cmip-pcmdi.llnl.gov/cmip5/> */
    description_attribution varchar,         /* attribution of the above */
    website varchar                          /* official project website */
);

/* Models may be associated with projects. */
drop table if exists model cascade;
create table model (
    identifier varchar not null primary key,  /* nccsm-4 */
    project_identifier varchar references project(identifier), /* cmip3 */
    name varchar,                             /* NCAR Community Climate System Model */
    version varchar,                          /* 4 */
    reference_url varchar not null,           /* URL with references about the model */
    website varchar,                          /* Model website */
    description varchar,
    description_attribution varchar
);
/* lexicons contain native ids : NCCSM, CCSM3, CGCM3.1 (T47), CNRM-CM3, CSIRO-Mk3.0.... */

/* A scenario */
drop table if exists scenario cascade;
create table scenario (
    identifier varchar not null primary key,   /* rcp8.5, sres_a2 */
    name varchar,                              /* Special Report on Emissions Scenarios Family A2 */
    description varchar,                       /*  ... */
    description_attribution varchar,           /* URL for description */
    CHECK (identifier similar to '[a-z0-9_-]+')
);

/* A model run uses an experiment and a model. */
drop table if exists model_run cascade;
create table model_run (
    identifier varchar not null primary key,   /* use a UUID */
    doi varchar,                               /* wishful thinking? */
    model_identifier varchar references model(identifier) on update cascade on delete cascade not null, /*  CCSM2 (as a GCID) */
    scenario_identifier varchar references scenario(identifier) on update cascade on delete cascade not null, /* RCP8.5,... */
    spatial_resolution varchar not null,                 /* 1 degree, ... */
    range_start date  not null,                          /* 1950-01-01, 1970-01-01 */
    range_end date not null,                             /* 2010-01-01, 1977-01-01 */
    sequence integer not null default 1,                 /* 1, 2, 3 */
    sequence_description varchar,                        /* "start one year earlier" */
    activity_identifier varchar references activity(identifier) on update cascade on delete cascade,
    project_identifier varchar references project(identifier) on update cascade on delete cascade, /* cmip5 */
    time_resolution interval,                            /* 1 day, 1 month, 6 hours */
    unique (model_identifier, scenario_identifier, spatial_resolution, range_start, range_end, sequence),
    unique (doi),
    CHECK (identifier similar to '[a-z0-9_-]+')
);

insert into publication_type (identifier, "table") values ('model','model');
insert into publication_type (identifier, "table") values ('scenario','scenario');

