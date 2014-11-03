                                             /* Sample values (comma separated) */

/* A project is a collection of experiments. */
create table project (
    identifier varchar not null primary key, /* cmip3, cmip4, cmip5 */
    name varchar,                            /* Coupled Model Intercomparison Project Phase 5 */
    description varchar                      /* a paragraph from <http://cmip-pcmdi.llnl.gov/cmip5/> */
);

/* Models are associated with projects. */
create table model (
    identifier varchar not null primary key,  /* ncar-community-climate-system-model-4 */
    project_identifier varchar not null references project(identifier), /* cmip5 */
    name varchar,                             /* NCAR Community Climate System Model */
    native_id varchar not null,               /* NCCSM, CCSM3, CGCM3.1 (T47), CNRM-CM3, CSIRO-Mk3.0.... */
    version varchar not null,                 /* 4 */
    unique (native_id, version),
    unique (identifier, project_identifier)
);

/* An experiment, which may be a scenario, aka "forcing data". */
create table experiment (
    identifier varchar not null primary key,   /* cmip5-representative-concentration-pathways-8.5 */
    native_id varchar not null,                /* RCP8.5, SRES A2 */
    description varchar,                       /*  "Representative Concentration Pathways" */
    CHECK (identifier similar to '[a-z0-9_-]+')
);

/* A model run uses an experiment and a model. */
create table model_run (
    identifier varchar not null,               /* use a UUID */
    doi varchar,                               /* wishful thinking? */
    project_identifier varchar references project(identifier), /* cmip5 */
    model_identifier varchar references model(identifier) not null, /*  CCSM2 (as a GCID) */
    experiment_identifier varchar references experiment(identifier) not null, /* RCP8.5,... */
    range_start timestamp without time zone not null,    /* 1950-01-01, 1970-01-01 */
    range_end timestamp without time zone not null,      /* 2010-01-01, 1977-01-01 */
    spatial_resolution varchar not null,      /* 1 degree, ... */
    time_resolution interval,                 /* 1 day, 1 month, 6 hours */
    sequence integer not null default 1,     /* 1, 2, 3 */
    sequence_description varchar,            /* "start one year earlier" */
    constraint fk_model_run_model_experiment foreign key
     (model_identifier, project_identifier) references model (identifier, project_identifier),
    unique (doi),
    CHECK (identifier similar to '[a-z0-9_-]+')
);

insert into publication_type (identifier, "table") values ('model','model');

/*
 * Notes and references :
 *
 * Organizations :
 *      http://cmip-pcmdi.llnl.gov/cmip5/availability.html
 * Search interface :
 *      http://pcmdi9.llnl.gov/esgf-web-fe/live#
 *
 * Contributors (organizations + roles) will be handled through the publication table.
 *
 * project vs experiment vs scenario
 *
 *   http://pcmdi9.llnl.gov/esgf-web-fe/live#
 *                    CMIP5 is a "project", RCP8.5 is an "experiment", not a scenario
 *
 *   http://cmip-pcmdi.llnl.gov/cmip5/index.html
 *                     CMIP5 is a "collection of experiments",
 *
 *   http://cmip-pcmdi.llnl.gov/cmip5/forcing.html
 *                      RCP is "forcing data"
 * 
 *
 *  native_id : are native_id's well defined and consistent globally unique identifiers?
 *      (or should we use lexicons?)
 *  Is "forcing data" a type of "scenario"?  Are there other "types" of scenarios?
 *  Might a scenario type be relative to an experiment?  (i.e. "cmip5 forcing vs cmip4 forcing")
 *  Should opaque identifers (e.g. UUIDs) be used for any of these?
 *  
 */



