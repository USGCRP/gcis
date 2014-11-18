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

/* Models are associated with projects. */
drop table if exists model cascade;
create table model (
    identifier varchar not null primary key,  /* ncar-community-climate-system-model-4 */
    name varchar,                             /* NCAR Community Climate System Model */
    native_id varchar not null,               /* NCCSM, CCSM3, CGCM3.1 (T47), CNRM-CM3, CSIRO-Mk3.0.... */
    version varchar,                          /* 4 */
    reference_url varchar not null,           /* URL with references about the model */
    website varchar,                          /* Model website */
    description varchar,
    description_attribution varchar,
    unique (native_id, version)
);

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
    identifier varchar not null,               /* use a UUID */
    doi varchar,                               /* wishful thinking? */
    activity_identifier varchar references activity(identifier),
    project_identifier varchar references project(identifier), /* cmip5 */
    model_identifier varchar references model(identifier) not null, /*  CCSM2 (as a GCID) */
    scenario_identifier varchar references scenario(identifier) not null, /* RCP8.5,... */
    range_start timestamp without time zone not null,    /* 1950-01-01, 1970-01-01 */
    range_end timestamp without time zone not null,      /* 2010-01-01, 1977-01-01 */
    spatial_resolution varchar not null,      /* 1 degree, ... */
    time_resolution interval,                 /* 1 day, 1 month, 6 hours */
    sequence integer not null default 1,     /* 1, 2, 3 */
    sequence_description varchar,            /* "start one year earlier" */
    unique (doi),
    CHECK (identifier similar to '[a-z0-9_-]+')
);

insert into publication_type (identifier, "table") values ('model','model');
insert into publication_type (identifier, "table") values ('scenario','scenario');

