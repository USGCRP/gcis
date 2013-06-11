
SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;





SET default_tablespace = '';

SET default_with_oids = false;


CREATE TABLE article (
    identifier character varying NOT NULL,
    title character varying,
    doi character varying,
    year integer,
    journal character varying,
    journal_vol character varying,
    journal_pages character varying,
    url character varying,
    notes character varying
);



CREATE TABLE chapter (
    identifier character varying NOT NULL,
    title character varying,
    report character varying,
    number integer
);



COMMENT ON COLUMN chapter.identifier IS 'A unique identifier for the chapter.';



CREATE TABLE contributor (
    id integer NOT NULL,
    person_id integer,
    organization_id integer,
    role_type character varying NOT NULL
);



CREATE SEQUENCE contributor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE contributor_id_seq OWNED BY contributor.id;



CREATE TABLE contributor_role_type (
    identifier character varying NOT NULL,
    "table" character varying
);



CREATE TABLE dataset (
    identifier character varying NOT NULL,
    name character varying,
    type character varying,
    version character varying,
    description character varying,
    native_id character varying,
    publication_dt timestamp(3) without time zone,
    access_dt timestamp(3) without time zone,
    url character varying,
    data_qualifier character varying,
    scale character varying,
    spatial_ref_sys character varying,
    cite_metadata character varying,
    scope character varying,
    spatial_extent character varying,
    temporal_extent character varying,
    vertical_extent character varying,
    processing_level character varying,
    spatial_res character varying
);



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
    identifier character varying NOT NULL,
    dataset character varying NOT NULL,
    organization_id integer NOT NULL
);



CREATE TABLE figure (
    identifier character varying NOT NULL,
    uuid character varying,
    chapter character varying,
    title character varying,
    caption character varying,
    attributes character varying,
    time_start timestamp(3) without time zone,
    time_end timestamp(3) without time zone,
    lat_max character varying,
    lat_min character varying,
    lon_max character varying,
    lon_min character varying,
    keywords character varying,
    usage_limits character varying,
    submission_dt timestamp(3) without time zone,
    create_dt timestamp(3) without time zone,
    source_citation character varying,
    ordinal integer
);



COMMENT ON COLUMN figure.identifier IS 'A unique identifier for the figure.';



CREATE TABLE file (
    identifier character varying NOT NULL,
    image character varying NOT NULL,
    file_type character varying,
    dir character varying,
    file character varying
);



CREATE TABLE finding (
    identifier character varying NOT NULL,
    chapter character varying,
    statement character varying
);



CREATE TABLE image (
    identifier character varying NOT NULL,
    figure character varying NOT NULL,
    "position" character varying,
    title character varying,
    description character varying,
    attributes character varying,
    time_start timestamp(3) without time zone,
    time_end timestamp(3) without time zone,
    lat_max character varying,
    lat_min character varying,
    lon_max character varying,
    lon_min character varying,
    keywords character varying,
    usage_limits character varying,
    submission_dt timestamp(3) without time zone,
    create_dt timestamp(3) without time zone
);



COMMENT ON COLUMN image.identifier IS 'A unique identifier for the image.';



CREATE TABLE journal (
    identifier character varying NOT NULL,
    title character varying,
    print_issn character varying,
    online_issn character varying,
    publisher character varying,
    country character varying,
    url character varying,
    notes character varying
);



CREATE TABLE org_academic (
    identifier character varying NOT NULL,
    title character varying,
    address character varying,
    email character varying,
    url character varying,
    country character varying,
    notes character varying
);



CREATE TABLE org_commercial (
    identifier character varying NOT NULL,
    title character varying,
    address character varying,
    email character varying,
    url character varying,
    country character varying,
    notes character varying
);



CREATE TABLE org_government (
    identifier character varying NOT NULL,
    title character varying,
    address character varying,
    email character varying,
    url character varying,
    country character varying,
    notes character varying
);



CREATE TABLE org_ngo (
    identifier character varying NOT NULL,
    title character varying,
    address character varying,
    email character varying,
    url character varying,
    country character varying,
    notes character varying
);



CREATE TABLE org_project (
    identifier character varying NOT NULL,
    title character varying,
    address character varying,
    email character varying,
    url character varying,
    country character varying,
    notes character varying
);



CREATE TABLE org_research (
    identifier character varying NOT NULL,
    title character varying,
    address character varying,
    email character varying,
    url character varying,
    country character varying,
    notes character varying
);



CREATE TABLE organization (
    id integer NOT NULL,
    organization_type character varying NOT NULL,
    fk character varying NOT NULL
);



CREATE SEQUENCE organization_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE organization_id_seq OWNED BY organization.id;



CREATE TABLE organization_type (
    identifier character varying NOT NULL,
    "table" character varying
);



CREATE TABLE person (
    id integer NOT NULL,
    name character varying,
    address character varying,
    phone character varying,
    email character varying,
    url character varying
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
    publication_type character varying NOT NULL,
    fk character varying NOT NULL
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
    type character varying NOT NULL,
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
    identifier character varying NOT NULL,
    "table" character varying
);



CREATE TABLE ref_type (
    identifier character varying NOT NULL,
    "table" character varying
);



CREATE TABLE report (
    identifier character varying NOT NULL,
    title character varying
);



COMMENT ON COLUMN report.identifier IS 'A unique identifier for the report.';



CREATE TABLE submitter (
    id integer NOT NULL,
    person_id integer,
    organization_id integer,
    "table" character varying,
    fk integer
);



CREATE SEQUENCE submitter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE submitter_id_seq OWNED BY submitter.id;



ALTER TABLE ONLY contributor ALTER COLUMN id SET DEFAULT nextval('contributor_id_seq'::regclass);



ALTER TABLE ONLY dataset_lineage ALTER COLUMN id SET DEFAULT nextval('dataset_lineage_id_seq'::regclass);



ALTER TABLE ONLY organization ALTER COLUMN id SET DEFAULT nextval('organization_id_seq'::regclass);



ALTER TABLE ONLY person ALTER COLUMN id SET DEFAULT nextval('person_id_seq'::regclass);



ALTER TABLE ONLY publication ALTER COLUMN id SET DEFAULT nextval('publication_id_seq'::regclass);



ALTER TABLE ONLY publication_contributor ALTER COLUMN id SET DEFAULT nextval('publication_contributor_id_seq'::regclass);



ALTER TABLE ONLY publication_ref ALTER COLUMN id SET DEFAULT nextval('publication_ref_id_seq'::regclass);



ALTER TABLE ONLY submitter ALTER COLUMN id SET DEFAULT nextval('submitter_id_seq'::regclass);



ALTER TABLE ONLY article
    ADD CONSTRAINT article_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_pkey PRIMARY KEY (id);



ALTER TABLE ONLY contributor_role_type
    ADD CONSTRAINT contributor_role_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY dataset_lineage
    ADD CONSTRAINT dataset_lineage_pkey PRIMARY KEY (id);



ALTER TABLE ONLY dataset_organization
    ADD CONSTRAINT dataset_organization_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY dataset
    ADD CONSTRAINT dataset_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY file
    ADD CONSTRAINT file_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY finding
    ADD CONSTRAINT finding_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY image
    ADD CONSTRAINT image_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY journal
    ADD CONSTRAINT journal_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY org_academic
    ADD CONSTRAINT org_academic_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY org_commercial
    ADD CONSTRAINT org_commercial_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY org_government
    ADD CONSTRAINT org_government_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY org_ngo
    ADD CONSTRAINT org_ngo_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY org_project
    ADD CONSTRAINT org_project_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY org_research
    ADD CONSTRAINT org_research_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);



ALTER TABLE ONLY organization_type
    ADD CONSTRAINT organization_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication_ref
    ADD CONSTRAINT publication_ref_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication_type
    ADD CONSTRAINT publication_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY ref_type
    ADD CONSTRAINT ref_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY report
    ADD CONSTRAINT report_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY submitter
    ADD CONSTRAINT submitter_pkey PRIMARY KEY (id);



ALTER TABLE ONLY chapter
    ADD CONSTRAINT uk_number UNIQUE (number);



ALTER TABLE ONLY article
    ADD CONSTRAINT article_ibfk_1 FOREIGN KEY (journal) REFERENCES journal(identifier) MATCH FULL;



ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_ibfk_1 FOREIGN KEY (report) REFERENCES report(identifier) MATCH FULL;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_1 FOREIGN KEY (person_id) REFERENCES person(id) MATCH FULL;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_2 FOREIGN KEY (organization_id) REFERENCES organization(id) MATCH FULL;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_3 FOREIGN KEY (role_type) REFERENCES contributor_role_type(identifier) MATCH FULL;



ALTER TABLE ONLY dataset_organization
    ADD CONSTRAINT dataset_organization_ibfk_1 FOREIGN KEY (dataset) REFERENCES dataset(identifier) MATCH FULL;



ALTER TABLE ONLY dataset_organization
    ADD CONSTRAINT dataset_organization_ibfk_2 FOREIGN KEY (organization_id) REFERENCES organization(id) MATCH FULL;



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_ibfk_1 FOREIGN KEY (chapter) REFERENCES chapter(identifier) MATCH FULL;



ALTER TABLE ONLY file
    ADD CONSTRAINT file_ibfk_1 FOREIGN KEY (image) REFERENCES image(identifier) MATCH FULL;



ALTER TABLE ONLY finding
    ADD CONSTRAINT finding_chapter_fkey FOREIGN KEY (chapter) REFERENCES chapter(identifier);



ALTER TABLE ONLY image
    ADD CONSTRAINT image_ibfk_1 FOREIGN KEY (figure) REFERENCES figure(identifier) MATCH FULL;



ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_ibfk_1 FOREIGN KEY (organization_type) REFERENCES organization_type(identifier) MATCH FULL;



ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_ibfk_2 FOREIGN KEY (contributor_id) REFERENCES contributor(id) MATCH FULL;



ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_ibfk_3 FOREIGN KEY (publication_id) REFERENCES publication(id) MATCH FULL;



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_ibfk_1 FOREIGN KEY (parent_id) REFERENCES publication(id) MATCH FULL;



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_ibfk_2 FOREIGN KEY (publication_type) REFERENCES publication_type(identifier) MATCH FULL;



ALTER TABLE ONLY publication_ref
    ADD CONSTRAINT publication_ref_ibfk_1 FOREIGN KEY (type) REFERENCES ref_type(identifier) MATCH FULL;



