                                             /* Sample values (comma separated) */
create table experiment (
    identifier varchar not null primary key, /* cmip3, cmip4, cmip5 */
    name varchar,                            /* Coupled Model Intercomparison Project Phase 5 */
    description varchar                      /* a paragraph from <http://cmip-pcmdi.llnl.gov/cmip5/> */
);

create table model (
    identifier varchar not null primary key,  /* ncar-community-climate-system-model */
    experiment_identifier varchar not null references experiment(identifier), /* cmip5 */
    name varchar,                             /* NCAR Community Climate System Model */
    native_id varchar not null,               /* NCCSM, CCSM3, CGCM3.1 (T47), CNRM-CM3, CSIRO-Mk3.0.... */
    version varchar not null,                 /* 4 */
    unique (native_id, version)
);

create table scenario_type (
    identifier varchar not null primary key,  /* forcing */
    description varchar                       /* http://cmip-pcmdi.llnl.gov/cmip5/forcing.html */
);

create table scenario (
    identifier varchar not null primary key,   /* cmip5-representative-concentration-pathways-8.5 */
    native_id varchar not null,                /* RCP8.5, SRES A2 */
    scenario_type_identifier varchar not null references scenario_type(identifier),  /* "forcing" */
    description varchar,                       /*  "Representative Concentration Pathways" */
    CHECK (identifier similar to '[a-z0-9_-]+')
);

create table model_run (
    identifier varchar not null,               /* use a UUID */
    doi varchar,                               /* wishful thinking? */
    experiment_identifier varchar references experiment(identifier), /* cmip5 */
    model_identifier varchar references model(identifier) not null, /*  CCSM2 (as a GCID) */
    range_start integer not null,             /* 1950-01-01, 1970-01-01 */
    range_end integer not null,               /* 2010-01-01, 1977-01-01 */
    spatial_resolution varchar not null,      /* 1 degree, ... */
    scenario_identifier varchar references scenario(identifier) not null, /* RCP8.5,... */
    sequence integer not null default 1,     /* 1, 2, 3 */
    sequence_description varchar,            /* "start one year earlier" */
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
 *                     CMIP5 is an "experiment",
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



