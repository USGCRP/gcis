
SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;





SET default_tablespace = '';

SET default_with_oids = false;


CREATE TABLE article (
    id integer NOT NULL,
    short_name character varying(64),
    title character varying(256),
    doi character varying(64),
    year integer,
    journal_id integer,
    journal_vol character varying(32),
    journal_pages character varying(32),
    url character varying(128),
    notes character varying(1024)
);



CREATE SEQUENCE article_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE article_id_seq OWNED BY article.id;



CREATE TABLE chapter (
    id integer NOT NULL,
    title character varying(256),
    report_id integer,
    number integer,
    short_name character varying NOT NULL
);



CREATE SEQUENCE chapter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE chapter_id_seq OWNED BY chapter.id;



CREATE TABLE contributor (
    id integer NOT NULL,
    person_id integer,
    organization_id integer,
    role_type_id integer
);



CREATE SEQUENCE contributor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE contributor_id_seq OWNED BY contributor.id;



CREATE TABLE contributor_role_type (
    id integer NOT NULL,
    name character varying(64),
    "table" character varying(64)
);



CREATE SEQUENCE contributor_role_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE contributor_role_type_id_seq OWNED BY contributor_role_type.id;



CREATE TABLE dataset (
    id integer NOT NULL,
    name character varying(45),
    type character varying(256),
    version character varying(45),
    description character varying(2048),
    native_id character varying(45),
    publication_dt timestamp(3) without time zone,
    access_dt timestamp(3) without time zone,
    url character varying(128),
    data_qualifier character varying(45),
    scale character varying(45),
    spatial_ref_sys character varying(45),
    cite_metadata character varying(45),
    scope character varying(45),
    spatial_extent character varying(512),
    temporal_extent character varying(512),
    vertical_extent character varying(45),
    processing_level character varying(45),
    spatial_res character varying(45)
);



CREATE SEQUENCE dataset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE dataset_id_seq OWNED BY dataset.id;



CREATE TABLE dataset_lineage (
    id integer NOT NULL,
    dataset_id integer,
    parent_id integer
);



CREATE SEQUENCE dataset_lineage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE dataset_lineage_id_seq OWNED BY dataset_lineage.id;



CREATE TABLE dataset_organization (
    id integer NOT NULL,
    dataset_id integer,
    organization_id integer
);



CREATE SEQUENCE dataset_organization_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE dataset_organization_id_seq OWNED BY dataset_organization.id;



CREATE TABLE figure (
    id integer NOT NULL,
    uuid character varying(36),
    chapter_id integer,
    title character varying(256),
    caption character varying(2048),
    attributes character varying(512),
    time_start timestamp(3) without time zone,
    time_end timestamp(3) without time zone,
    lat_max character varying(45),
    lat_min character varying(45),
    lon_max character varying(45),
    lon_min character varying(45),
    keywords character varying(512),
    usage_limits character varying(512),
    submission_dt timestamp(3) without time zone,
    create_dt timestamp(3) without time zone,
    source_citation character varying(256),
    ordinal integer
);



CREATE SEQUENCE figure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE figure_id_seq OWNED BY figure.id;



CREATE TABLE file (
    id integer NOT NULL,
    image_id integer,
    file_type character varying(45),
    dir character varying(512),
    file character varying(512)
);



CREATE SEQUENCE file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE file_id_seq OWNED BY file.id;



CREATE TABLE image (
    id integer NOT NULL,
    figure_id integer NOT NULL,
    "position" character varying(45),
    title character varying(256),
    description character varying(2048),
    attributes character varying(128),
    time_start timestamp(3) without time zone,
    time_end timestamp(3) without time zone,
    lat_max character varying(45),
    lat_min character varying(45),
    lon_max character varying(45),
    lon_min character varying(45),
    keywords character varying(512),
    usage_limits character varying(128),
    submission_dt timestamp(3) without time zone,
    create_dt timestamp(3) without time zone
);



CREATE SEQUENCE image_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE image_id_seq OWNED BY image.id;



CREATE TABLE journal (
    id integer NOT NULL,
    short_name character varying(64),
    title character varying(128),
    print_issn character varying(128),
    online_issn character varying(32),
    publisher character varying(128),
    country character varying(32),
    url character varying(128),
    notes character varying(1024)
);



CREATE SEQUENCE journal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE journal_id_seq OWNED BY journal.id;



CREATE TABLE org_academic (
    id integer NOT NULL,
    short_name character varying(45),
    long_name character varying(256),
    address character varying(45),
    email character varying(45),
    url character varying(128),
    notes character varying(1024)
);



CREATE SEQUENCE org_academic_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE org_academic_id_seq OWNED BY org_academic.id;



CREATE TABLE org_commercial (
    id integer NOT NULL,
    short_name character varying(45),
    long_name character varying(256),
    address character varying(45),
    email character varying(45),
    url character varying(128),
    notes character varying(1024)
);



CREATE SEQUENCE org_commercial_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE org_commercial_id_seq OWNED BY org_commercial.id;



CREATE TABLE org_government (
    id integer NOT NULL,
    short_name character varying(45),
    long_name character varying(256),
    address character varying(45),
    email character varying(45),
    url character varying(128),
    notes character varying(1024)
);



CREATE SEQUENCE org_government_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE org_government_id_seq OWNED BY org_government.id;



CREATE TABLE org_project (
    id integer NOT NULL,
    short_name character varying(45),
    long_name character varying(256),
    address character varying(45),
    email character varying(45),
    url character varying(128),
    notes character varying(1024)
);



CREATE SEQUENCE org_project_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE org_project_id_seq OWNED BY org_project.id;



CREATE TABLE organization (
    id integer NOT NULL,
    organization_type integer,
    fk integer
);



CREATE SEQUENCE organization_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE organization_id_seq OWNED BY organization.id;



CREATE TABLE organization_type (
    id integer NOT NULL,
    name character varying(64),
    "table" character varying(64)
);



CREATE SEQUENCE organization_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE organization_type_id_seq OWNED BY organization_type.id;



CREATE TABLE person (
    id integer NOT NULL,
    name character varying(45),
    address character varying(45),
    phone character varying(45),
    email character varying(45),
    url character varying(128)
);



CREATE SEQUENCE person_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE person_id_seq OWNED BY person.id;



CREATE TABLE publication (
    id integer NOT NULL,
    parent_id integer,
    publication_type_id integer,
    fk integer
);



CREATE TABLE publication_contributor (
    id integer NOT NULL,
    publication_id integer,
    contributor_id integer
);



CREATE SEQUENCE publication_contributor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE publication_contributor_id_seq OWNED BY publication_contributor.id;



CREATE SEQUENCE publication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE publication_id_seq OWNED BY publication.id;



CREATE TABLE publication_ref (
    id integer NOT NULL,
    publication_id integer,
    type integer NOT NULL,
    fk integer NOT NULL
);



CREATE SEQUENCE publication_ref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE publication_ref_id_seq OWNED BY publication_ref.id;



CREATE TABLE publication_type (
    id integer NOT NULL,
    name character varying(64),
    "table" character varying(64)
);



CREATE SEQUENCE publication_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE publication_type_id_seq OWNED BY publication_type.id;



CREATE TABLE ref_type (
    id integer NOT NULL,
    name character varying(64),
    "table" character varying(64)
);



CREATE SEQUENCE ref_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE ref_type_id_seq OWNED BY ref_type.id;



CREATE TABLE report (
    id integer NOT NULL,
    short_name character varying(45),
    title character varying(256)
);



CREATE SEQUENCE report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE report_id_seq OWNED BY report.id;



CREATE TABLE submitter (
    id integer NOT NULL,
    person_id integer,
    organization_id integer,
    "table" character varying(64),
    fk integer
);



CREATE SEQUENCE submitter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE submitter_id_seq OWNED BY submitter.id;



ALTER TABLE ONLY article ALTER COLUMN id SET DEFAULT nextval('article_id_seq'::regclass);



ALTER TABLE ONLY chapter ALTER COLUMN id SET DEFAULT nextval('chapter_id_seq'::regclass);



ALTER TABLE ONLY contributor ALTER COLUMN id SET DEFAULT nextval('contributor_id_seq'::regclass);



ALTER TABLE ONLY contributor_role_type ALTER COLUMN id SET DEFAULT nextval('contributor_role_type_id_seq'::regclass);



ALTER TABLE ONLY dataset ALTER COLUMN id SET DEFAULT nextval('dataset_id_seq'::regclass);



ALTER TABLE ONLY dataset_lineage ALTER COLUMN id SET DEFAULT nextval('dataset_lineage_id_seq'::regclass);



ALTER TABLE ONLY dataset_organization ALTER COLUMN id SET DEFAULT nextval('dataset_organization_id_seq'::regclass);



ALTER TABLE ONLY figure ALTER COLUMN id SET DEFAULT nextval('figure_id_seq'::regclass);



ALTER TABLE ONLY file ALTER COLUMN id SET DEFAULT nextval('file_id_seq'::regclass);



ALTER TABLE ONLY image ALTER COLUMN id SET DEFAULT nextval('image_id_seq'::regclass);



ALTER TABLE ONLY journal ALTER COLUMN id SET DEFAULT nextval('journal_id_seq'::regclass);



ALTER TABLE ONLY org_academic ALTER COLUMN id SET DEFAULT nextval('org_academic_id_seq'::regclass);



ALTER TABLE ONLY org_commercial ALTER COLUMN id SET DEFAULT nextval('org_commercial_id_seq'::regclass);



ALTER TABLE ONLY org_government ALTER COLUMN id SET DEFAULT nextval('org_government_id_seq'::regclass);



ALTER TABLE ONLY org_project ALTER COLUMN id SET DEFAULT nextval('org_project_id_seq'::regclass);



ALTER TABLE ONLY organization ALTER COLUMN id SET DEFAULT nextval('organization_id_seq'::regclass);



ALTER TABLE ONLY organization_type ALTER COLUMN id SET DEFAULT nextval('organization_type_id_seq'::regclass);



ALTER TABLE ONLY person ALTER COLUMN id SET DEFAULT nextval('person_id_seq'::regclass);



ALTER TABLE ONLY publication ALTER COLUMN id SET DEFAULT nextval('publication_id_seq'::regclass);



ALTER TABLE ONLY publication_contributor ALTER COLUMN id SET DEFAULT nextval('publication_contributor_id_seq'::regclass);



ALTER TABLE ONLY publication_ref ALTER COLUMN id SET DEFAULT nextval('publication_ref_id_seq'::regclass);



ALTER TABLE ONLY publication_type ALTER COLUMN id SET DEFAULT nextval('publication_type_id_seq'::regclass);



ALTER TABLE ONLY ref_type ALTER COLUMN id SET DEFAULT nextval('ref_type_id_seq'::regclass);



ALTER TABLE ONLY report ALTER COLUMN id SET DEFAULT nextval('report_id_seq'::regclass);



ALTER TABLE ONLY submitter ALTER COLUMN id SET DEFAULT nextval('submitter_id_seq'::regclass);



ALTER TABLE ONLY article
    ADD CONSTRAINT article_pkey PRIMARY KEY (id);



ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_pkey PRIMARY KEY (id);



ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_short_name_key UNIQUE (short_name);



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_pkey PRIMARY KEY (id);



ALTER TABLE ONLY contributor_role_type
    ADD CONSTRAINT contributor_role_type_pkey PRIMARY KEY (id);



ALTER TABLE ONLY dataset_lineage
    ADD CONSTRAINT dataset_lineage_pkey PRIMARY KEY (id);



ALTER TABLE ONLY dataset_organization
    ADD CONSTRAINT dataset_organization_pkey PRIMARY KEY (id);



ALTER TABLE ONLY dataset
    ADD CONSTRAINT dataset_pkey PRIMARY KEY (id);



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_pkey PRIMARY KEY (id);



ALTER TABLE ONLY file
    ADD CONSTRAINT file_pkey PRIMARY KEY (id);



ALTER TABLE ONLY image
    ADD CONSTRAINT image_pkey PRIMARY KEY (id);



ALTER TABLE ONLY journal
    ADD CONSTRAINT journal_pkey PRIMARY KEY (id);



ALTER TABLE ONLY org_academic
    ADD CONSTRAINT org_academic_pkey PRIMARY KEY (id);



ALTER TABLE ONLY org_commercial
    ADD CONSTRAINT org_commercial_pkey PRIMARY KEY (id);



ALTER TABLE ONLY org_government
    ADD CONSTRAINT org_government_pkey PRIMARY KEY (id);



ALTER TABLE ONLY org_project
    ADD CONSTRAINT org_project_pkey PRIMARY KEY (id);



ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);



ALTER TABLE ONLY organization_type
    ADD CONSTRAINT organization_type_pkey PRIMARY KEY (id);



ALTER TABLE ONLY person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication_ref
    ADD CONSTRAINT publication_ref_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication_type
    ADD CONSTRAINT publication_type_pkey PRIMARY KEY (id);



ALTER TABLE ONLY ref_type
    ADD CONSTRAINT ref_type_pkey PRIMARY KEY (id);



ALTER TABLE ONLY report
    ADD CONSTRAINT report_pkey PRIMARY KEY (id);



ALTER TABLE ONLY submitter
    ADD CONSTRAINT submitter_pkey PRIMARY KEY (id);



ALTER TABLE ONLY article
    ADD CONSTRAINT article_ibfk_1 FOREIGN KEY (journal_id) REFERENCES journal(id) MATCH FULL;



ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_report_id_fkey FOREIGN KEY (report_id) REFERENCES report(id);



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_1 FOREIGN KEY (person_id) REFERENCES person(id) MATCH FULL;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_2 FOREIGN KEY (organization_id) REFERENCES organization(id) MATCH FULL;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_3 FOREIGN KEY (role_type_id) REFERENCES contributor_role_type(id) MATCH FULL;



ALTER TABLE ONLY dataset_organization
    ADD CONSTRAINT dataset_organization_ibfk_1 FOREIGN KEY (dataset_id) REFERENCES dataset(id) MATCH FULL;



ALTER TABLE ONLY dataset_organization
    ADD CONSTRAINT dataset_organization_ibfk_2 FOREIGN KEY (organization_id) REFERENCES organization(id) MATCH FULL;



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_ibfk_1 FOREIGN KEY (chapter_id) REFERENCES chapter(id) MATCH FULL;



ALTER TABLE ONLY file
    ADD CONSTRAINT file_ibfk_1 FOREIGN KEY (image_id) REFERENCES image(id) MATCH FULL;



ALTER TABLE ONLY image
    ADD CONSTRAINT image_ibfk_1 FOREIGN KEY (figure_id) REFERENCES figure(id) MATCH FULL;



ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_ibfk_1 FOREIGN KEY (organization_type) REFERENCES organization_type(id) MATCH FULL;



ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_ibfk_2 FOREIGN KEY (contributor_id) REFERENCES contributor(id) MATCH FULL;



ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_ibfk_3 FOREIGN KEY (publication_id) REFERENCES publication(id) MATCH FULL;



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_ibfk_1 FOREIGN KEY (parent_id) REFERENCES publication(id) MATCH FULL;



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_ibfk_2 FOREIGN KEY (publication_type_id) REFERENCES publication_type(id) MATCH FULL;



ALTER TABLE ONLY publication_ref
    ADD CONSTRAINT publication_ref_ibfk_1 FOREIGN KEY (type) REFERENCES ref_type(id) MATCH FULL;



