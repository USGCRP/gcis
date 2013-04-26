--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: gcis_metadata; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA gcis_metadata;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = gcis_metadata, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: article; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

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


--
-- Name: article_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE article_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: article_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE article_id_seq OWNED BY article.id;


--
-- Name: chapter; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE chapter (
    id integer NOT NULL,
    short_name character varying(45),
    title character varying(256),
    report_id integer
);


--
-- Name: chapter_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE chapter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chapter_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE chapter_id_seq OWNED BY chapter.id;


--
-- Name: contributor; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE contributor (
    id integer NOT NULL,
    person_id integer,
    organization_id integer,
    role_type_id integer
);


--
-- Name: contributor_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE contributor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contributor_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE contributor_id_seq OWNED BY contributor.id;


--
-- Name: contributor_role_type; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE contributor_role_type (
    id integer NOT NULL,
    name character varying(64),
    "table" character varying(64)
);


--
-- Name: contributor_role_type_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE contributor_role_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contributor_role_type_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE contributor_role_type_id_seq OWNED BY contributor_role_type.id;


--
-- Name: dataset; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

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


--
-- Name: dataset_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE dataset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dataset_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE dataset_id_seq OWNED BY dataset.id;


--
-- Name: dataset_lineage; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE dataset_lineage (
    id integer NOT NULL,
    dataset_id integer,
    parent_id integer
);


--
-- Name: dataset_lineage_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE dataset_lineage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dataset_lineage_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE dataset_lineage_id_seq OWNED BY dataset_lineage.id;


--
-- Name: dataset_organization; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE dataset_organization (
    id integer NOT NULL,
    dataset_id integer,
    organization_id integer
);


--
-- Name: dataset_organization_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE dataset_organization_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dataset_organization_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE dataset_organization_id_seq OWNED BY dataset_organization.id;


--
-- Name: figure; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

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


--
-- Name: figure_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE figure_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: figure_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE figure_id_seq OWNED BY figure.id;


--
-- Name: file; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE file (
    id integer NOT NULL,
    image_id integer,
    file_type character varying(45),
    dir character varying(512),
    file character varying(512)
);


--
-- Name: file_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: file_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE file_id_seq OWNED BY file.id;


--
-- Name: image; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

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


--
-- Name: image_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE image_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: image_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE image_id_seq OWNED BY image.id;


--
-- Name: journal; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

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


--
-- Name: journal_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE journal_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: journal_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE journal_id_seq OWNED BY journal.id;


--
-- Name: org_academic; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE org_academic (
    id integer NOT NULL,
    short_name character varying(45),
    long_name character varying(256),
    address character varying(45),
    email character varying(45),
    url character varying(128),
    notes character varying(1024)
);


--
-- Name: org_academic_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE org_academic_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: org_academic_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE org_academic_id_seq OWNED BY org_academic.id;


--
-- Name: org_commercial; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE org_commercial (
    id integer NOT NULL,
    short_name character varying(45),
    long_name character varying(256),
    address character varying(45),
    email character varying(45),
    url character varying(128),
    notes character varying(1024)
);


--
-- Name: org_commercial_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE org_commercial_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: org_commercial_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE org_commercial_id_seq OWNED BY org_commercial.id;


--
-- Name: org_government; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE org_government (
    id integer NOT NULL,
    short_name character varying(45),
    long_name character varying(256),
    address character varying(45),
    email character varying(45),
    url character varying(128),
    notes character varying(1024)
);


--
-- Name: org_government_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE org_government_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: org_government_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE org_government_id_seq OWNED BY org_government.id;


--
-- Name: org_project; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE org_project (
    id integer NOT NULL,
    short_name character varying(45),
    long_name character varying(256),
    address character varying(45),
    email character varying(45),
    url character varying(128),
    notes character varying(1024)
);


--
-- Name: org_project_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE org_project_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: org_project_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE org_project_id_seq OWNED BY org_project.id;


--
-- Name: organization; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE organization (
    id integer NOT NULL,
    organization_type integer,
    fk integer
);


--
-- Name: organization_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE organization_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organization_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE organization_id_seq OWNED BY organization.id;


--
-- Name: organization_type; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE organization_type (
    id integer NOT NULL,
    name character varying(64),
    "table" character varying(64)
);


--
-- Name: organization_type_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE organization_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organization_type_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE organization_type_id_seq OWNED BY organization_type.id;


--
-- Name: person; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE person (
    id integer NOT NULL,
    name character varying(45),
    address character varying(45),
    phone character varying(45),
    email character varying(45),
    url character varying(128)
);


--
-- Name: person_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE person_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: person_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE person_id_seq OWNED BY person.id;


--
-- Name: publication; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE publication (
    id integer NOT NULL,
    parent_id integer,
    publication_type_id integer,
    fk integer
);


--
-- Name: publication_contributor; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE publication_contributor (
    id integer NOT NULL,
    publication_id integer,
    contributor_id integer
);


--
-- Name: publication_contributor_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE publication_contributor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: publication_contributor_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE publication_contributor_id_seq OWNED BY publication_contributor.id;


--
-- Name: publication_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE publication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: publication_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE publication_id_seq OWNED BY publication.id;


--
-- Name: publication_ref; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE publication_ref (
    id integer NOT NULL,
    publication_id integer,
    type integer NOT NULL,
    fk integer NOT NULL
);


--
-- Name: publication_ref_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE publication_ref_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: publication_ref_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE publication_ref_id_seq OWNED BY publication_ref.id;


--
-- Name: publication_type; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE publication_type (
    id integer NOT NULL,
    name character varying(64),
    "table" character varying(64)
);


--
-- Name: publication_type_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE publication_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: publication_type_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE publication_type_id_seq OWNED BY publication_type.id;


--
-- Name: ref_type; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE ref_type (
    id integer NOT NULL,
    name character varying(64),
    "table" character varying(64)
);


--
-- Name: ref_type_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE ref_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ref_type_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE ref_type_id_seq OWNED BY ref_type.id;


--
-- Name: report; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE report (
    id integer NOT NULL,
    short_name character varying(45),
    title character varying(256)
);


--
-- Name: report_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE report_id_seq OWNED BY report.id;


--
-- Name: submitter; Type: TABLE; Schema: gcis_metadata; Owner: -; Tablespace: 
--

CREATE TABLE submitter (
    id integer NOT NULL,
    person_id integer,
    organization_id integer,
    "table" character varying(64),
    fk integer
);


--
-- Name: submitter_id_seq; Type: SEQUENCE; Schema: gcis_metadata; Owner: -
--

CREATE SEQUENCE submitter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: submitter_id_seq; Type: SEQUENCE OWNED BY; Schema: gcis_metadata; Owner: -
--

ALTER SEQUENCE submitter_id_seq OWNED BY submitter.id;


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY article ALTER COLUMN id SET DEFAULT nextval('article_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY chapter ALTER COLUMN id SET DEFAULT nextval('chapter_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY contributor ALTER COLUMN id SET DEFAULT nextval('contributor_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY contributor_role_type ALTER COLUMN id SET DEFAULT nextval('contributor_role_type_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY dataset ALTER COLUMN id SET DEFAULT nextval('dataset_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY dataset_lineage ALTER COLUMN id SET DEFAULT nextval('dataset_lineage_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY dataset_organization ALTER COLUMN id SET DEFAULT nextval('dataset_organization_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY figure ALTER COLUMN id SET DEFAULT nextval('figure_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY file ALTER COLUMN id SET DEFAULT nextval('file_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY image ALTER COLUMN id SET DEFAULT nextval('image_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY journal ALTER COLUMN id SET DEFAULT nextval('journal_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY org_academic ALTER COLUMN id SET DEFAULT nextval('org_academic_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY org_commercial ALTER COLUMN id SET DEFAULT nextval('org_commercial_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY org_government ALTER COLUMN id SET DEFAULT nextval('org_government_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY org_project ALTER COLUMN id SET DEFAULT nextval('org_project_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY organization ALTER COLUMN id SET DEFAULT nextval('organization_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY organization_type ALTER COLUMN id SET DEFAULT nextval('organization_type_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY person ALTER COLUMN id SET DEFAULT nextval('person_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication ALTER COLUMN id SET DEFAULT nextval('publication_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication_contributor ALTER COLUMN id SET DEFAULT nextval('publication_contributor_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication_ref ALTER COLUMN id SET DEFAULT nextval('publication_ref_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication_type ALTER COLUMN id SET DEFAULT nextval('publication_type_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY ref_type ALTER COLUMN id SET DEFAULT nextval('ref_type_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY report ALTER COLUMN id SET DEFAULT nextval('report_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY submitter ALTER COLUMN id SET DEFAULT nextval('submitter_id_seq'::regclass);


--
-- Data for Name: article; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY article (id, short_name, title, doi, year, journal_id, journal_vol, journal_pages, url, notes) FROM stdin;
\.


--
-- Name: article_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('article_id_seq', 1, false);


--
-- Data for Name: chapter; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY chapter (id, short_name, title, report_id) FROM stdin;
\.


--
-- Name: chapter_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('chapter_id_seq', 1, false);


--
-- Data for Name: contributor; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY contributor (id, person_id, organization_id, role_type_id) FROM stdin;
\.


--
-- Name: contributor_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('contributor_id_seq', 1, false);


--
-- Data for Name: contributor_role_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY contributor_role_type (id, name, "table") FROM stdin;
\.


--
-- Name: contributor_role_type_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('contributor_role_type_id_seq', 1, false);


--
-- Data for Name: dataset; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY dataset (id, name, type, version, description, native_id, publication_dt, access_dt, url, data_qualifier, scale, spatial_ref_sys, cite_metadata, scope, spatial_extent, temporal_extent, vertical_extent, processing_level, spatial_res) FROM stdin;
\.


--
-- Name: dataset_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('dataset_id_seq', 1, false);


--
-- Data for Name: dataset_lineage; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY dataset_lineage (id, dataset_id, parent_id) FROM stdin;
\.


--
-- Name: dataset_lineage_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('dataset_lineage_id_seq', 1, false);


--
-- Data for Name: dataset_organization; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY dataset_organization (id, dataset_id, organization_id) FROM stdin;
\.


--
-- Name: dataset_organization_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('dataset_organization_id_seq', 1, false);


--
-- Data for Name: figure; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY figure (id, uuid, chapter_id, title, caption, attributes, time_start, time_end, lat_max, lat_min, lon_max, lon_min, keywords, usage_limits, submission_dt, create_dt, source_citation, ordinal) FROM stdin;
\.


--
-- Name: figure_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('figure_id_seq', 1, false);


--
-- Data for Name: file; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY file (id, image_id, file_type, dir, file) FROM stdin;
\.


--
-- Name: file_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('file_id_seq', 1, false);


--
-- Data for Name: image; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY image (id, figure_id, "position", title, description, attributes, time_start, time_end, lat_max, lat_min, lon_max, lon_min, keywords, usage_limits, submission_dt, create_dt) FROM stdin;
\.


--
-- Name: image_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('image_id_seq', 1, false);


--
-- Data for Name: journal; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY journal (id, short_name, title, print_issn, online_issn, publisher, country, url, notes) FROM stdin;
\.


--
-- Name: journal_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('journal_id_seq', 1, false);


--
-- Data for Name: org_academic; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_academic (id, short_name, long_name, address, email, url, notes) FROM stdin;
\.


--
-- Name: org_academic_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('org_academic_id_seq', 1, false);


--
-- Data for Name: org_commercial; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_commercial (id, short_name, long_name, address, email, url, notes) FROM stdin;
\.


--
-- Name: org_commercial_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('org_commercial_id_seq', 1, false);


--
-- Data for Name: org_government; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_government (id, short_name, long_name, address, email, url, notes) FROM stdin;
\.


--
-- Name: org_government_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('org_government_id_seq', 1, false);


--
-- Data for Name: org_project; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY org_project (id, short_name, long_name, address, email, url, notes) FROM stdin;
\.


--
-- Name: org_project_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('org_project_id_seq', 1, false);


--
-- Data for Name: organization; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY organization (id, organization_type, fk) FROM stdin;
\.


--
-- Name: organization_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('organization_id_seq', 1, false);


--
-- Data for Name: organization_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY organization_type (id, name, "table") FROM stdin;
\.


--
-- Name: organization_type_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('organization_type_id_seq', 1, false);


--
-- Data for Name: person; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY person (id, name, address, phone, email, url) FROM stdin;
\.


--
-- Name: person_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('person_id_seq', 1, false);


--
-- Data for Name: publication; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication (id, parent_id, publication_type_id, fk) FROM stdin;
\.


--
-- Data for Name: publication_contributor; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_contributor (id, publication_id, contributor_id) FROM stdin;
\.


--
-- Name: publication_contributor_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('publication_contributor_id_seq', 1, false);


--
-- Name: publication_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('publication_id_seq', 1, false);


--
-- Data for Name: publication_ref; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_ref (id, publication_id, type, fk) FROM stdin;
\.


--
-- Name: publication_ref_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('publication_ref_id_seq', 1, false);


--
-- Data for Name: publication_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY publication_type (id, name, "table") FROM stdin;
\.


--
-- Name: publication_type_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('publication_type_id_seq', 1, false);


--
-- Data for Name: ref_type; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY ref_type (id, name, "table") FROM stdin;
\.


--
-- Name: ref_type_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('ref_type_id_seq', 1, false);


--
-- Data for Name: report; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY report (id, short_name, title) FROM stdin;
\.


--
-- Name: report_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('report_id_seq', 1, false);


--
-- Data for Name: submitter; Type: TABLE DATA; Schema: gcis_metadata; Owner: -
--

COPY submitter (id, person_id, organization_id, "table", fk) FROM stdin;
\.


--
-- Name: submitter_id_seq; Type: SEQUENCE SET; Schema: gcis_metadata; Owner: -
--

SELECT pg_catalog.setval('submitter_id_seq', 1, false);


--
-- Name: article_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY article
    ADD CONSTRAINT article_pkey PRIMARY KEY (id);


--
-- Name: chapter_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_pkey PRIMARY KEY (id);


--
-- Name: contributor_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_pkey PRIMARY KEY (id);


--
-- Name: contributor_role_type_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contributor_role_type
    ADD CONSTRAINT contributor_role_type_pkey PRIMARY KEY (id);


--
-- Name: dataset_lineage_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dataset_lineage
    ADD CONSTRAINT dataset_lineage_pkey PRIMARY KEY (id);


--
-- Name: dataset_organization_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dataset_organization
    ADD CONSTRAINT dataset_organization_pkey PRIMARY KEY (id);


--
-- Name: dataset_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dataset
    ADD CONSTRAINT dataset_pkey PRIMARY KEY (id);


--
-- Name: figure_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_pkey PRIMARY KEY (id);


--
-- Name: file_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_pkey PRIMARY KEY (id);


--
-- Name: image_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY image
    ADD CONSTRAINT image_pkey PRIMARY KEY (id);


--
-- Name: journal_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY journal
    ADD CONSTRAINT journal_pkey PRIMARY KEY (id);


--
-- Name: org_academic_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY org_academic
    ADD CONSTRAINT org_academic_pkey PRIMARY KEY (id);


--
-- Name: org_commercial_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY org_commercial
    ADD CONSTRAINT org_commercial_pkey PRIMARY KEY (id);


--
-- Name: org_government_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY org_government
    ADD CONSTRAINT org_government_pkey PRIMARY KEY (id);


--
-- Name: org_project_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY org_project
    ADD CONSTRAINT org_project_pkey PRIMARY KEY (id);


--
-- Name: organization_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (id);


--
-- Name: organization_type_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY organization_type
    ADD CONSTRAINT organization_type_pkey PRIMARY KEY (id);


--
-- Name: person_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);


--
-- Name: publication_contributor_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_pkey PRIMARY KEY (id);


--
-- Name: publication_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_pkey PRIMARY KEY (id);


--
-- Name: publication_ref_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY publication_ref
    ADD CONSTRAINT publication_ref_pkey PRIMARY KEY (id);


--
-- Name: publication_type_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY publication_type
    ADD CONSTRAINT publication_type_pkey PRIMARY KEY (id);


--
-- Name: ref_type_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ref_type
    ADD CONSTRAINT ref_type_pkey PRIMARY KEY (id);


--
-- Name: report_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY report
    ADD CONSTRAINT report_pkey PRIMARY KEY (id);


--
-- Name: submitter_pkey; Type: CONSTRAINT; Schema: gcis_metadata; Owner: -; Tablespace: 
--

ALTER TABLE ONLY submitter
    ADD CONSTRAINT submitter_pkey PRIMARY KEY (id);


--
-- Name: article_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY article
    ADD CONSTRAINT article_ibfk_1 FOREIGN KEY (journal_id) REFERENCES journal(id) MATCH FULL;


--
-- Name: chapter_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_ibfk_1 FOREIGN KEY (report_id) REFERENCES report(id) MATCH FULL;


--
-- Name: contributor_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_1 FOREIGN KEY (person_id) REFERENCES person(id) MATCH FULL;


--
-- Name: contributor_ibfk_2; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_2 FOREIGN KEY (organization_id) REFERENCES organization(id) MATCH FULL;


--
-- Name: contributor_ibfk_3; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_3 FOREIGN KEY (role_type_id) REFERENCES contributor_role_type(id) MATCH FULL;


--
-- Name: dataset_organization_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY dataset_organization
    ADD CONSTRAINT dataset_organization_ibfk_1 FOREIGN KEY (dataset_id) REFERENCES dataset(id) MATCH FULL;


--
-- Name: dataset_organization_ibfk_2; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY dataset_organization
    ADD CONSTRAINT dataset_organization_ibfk_2 FOREIGN KEY (organization_id) REFERENCES organization(id) MATCH FULL;


--
-- Name: figure_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_ibfk_1 FOREIGN KEY (chapter_id) REFERENCES chapter(id) MATCH FULL;


--
-- Name: file_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY file
    ADD CONSTRAINT file_ibfk_1 FOREIGN KEY (image_id) REFERENCES image(id) MATCH FULL;


--
-- Name: image_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY image
    ADD CONSTRAINT image_ibfk_1 FOREIGN KEY (figure_id) REFERENCES figure(id) MATCH FULL;


--
-- Name: organization_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_ibfk_1 FOREIGN KEY (organization_type) REFERENCES organization_type(id) MATCH FULL;


--
-- Name: publication_contributor_ibfk_2; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_ibfk_2 FOREIGN KEY (contributor_id) REFERENCES contributor(id) MATCH FULL;


--
-- Name: publication_contributor_ibfk_3; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication_contributor
    ADD CONSTRAINT publication_contributor_ibfk_3 FOREIGN KEY (publication_id) REFERENCES publication(id) MATCH FULL;


--
-- Name: publication_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_ibfk_1 FOREIGN KEY (parent_id) REFERENCES publication(id) MATCH FULL;


--
-- Name: publication_ibfk_2; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_ibfk_2 FOREIGN KEY (publication_type_id) REFERENCES publication_type(id) MATCH FULL;


--
-- Name: publication_ref_ibfk_1; Type: FK CONSTRAINT; Schema: gcis_metadata; Owner: -
--

ALTER TABLE ONLY publication_ref
    ADD CONSTRAINT publication_ref_ibfk_1 FOREIGN KEY (type) REFERENCES ref_type(id) MATCH FULL;


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

