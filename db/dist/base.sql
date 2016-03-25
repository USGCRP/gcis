
SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;






CREATE FUNCTION copy_exterm_inserts_to_term() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    --populate context
    IF NOT EXISTS (SELECT * FROM context c
                   WHERE c.identifier = NEW.context)
    THEN INSERT INTO context (lexicon_identifier, identifier, version)
                VALUES (NEW.lexicon_identifier, NEW.context, '');
    END IF;
    --populate term
    INSERT INTO term (lexicon_identifier, context_identifier, term)
           VALUES (NEW.lexicon_identifier, NEW.context, NEW.term);
    --populate term_map
    INSERT INTO term_map (term_identifier, relationship, gcid)
           (SELECT t.identifier, 'owl:sameAs', NEW.gcid
            FROM term AS t
            WHERE t.term = NEW.term
              AND t.lexicon_identifier = NEW.lexicon_identifier
              AND t.context_identifier = NEW.context
           );
    RETURN NEW;
END; $$;



COMMENT ON FUNCTION copy_exterm_inserts_to_term() IS '
Populate fields in tables ''context'', ''term'', and ''term_map'' for new entries in
''exterm'' table.
This is to keep these new tables in sync with any new data entered into exterm
during the transition to using the new tables in the perl code.
';



CREATE FUNCTION delete_publication() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    delete from publication
         where publication_type_identifier = TG_TABLE_NAME::text and
            fk = slice(hstore(OLD.*),akeys(fk));
    RETURN OLD;
END; $$;



CREATE FUNCTION name_hash(first_name text, last_name text) RETURNS character varying
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
return 
    concat(
        regexp_replace(lower(first_name),'\W','','g'),
        regexp_replace(lower(last_name),'\W','','g')
    );
END; $$;



CREATE FUNCTION name_unique_hash(first_name text, last_name text, orcid text) RETURNS character varying
    LANGUAGE plpgsql IMMUTABLE
    AS $$
BEGIN
return concat( name_hash(first_name, last_name), orcid );
END; $$;



CREATE FUNCTION update_exterms() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    /* params are old, new */
    update exterm set gcid = TG_ARGV[0] || NEW.identifier where gcid = TG_ARGV[0] ||  OLD.identifier;
    RETURN NEW;
END; $$;



CREATE FUNCTION update_publication() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    update publication set fk = slice(hstore(NEW.*),akeys(fk))
         where publication_type_identifier = TG_TABLE_NAME::text and
            fk = slice(hstore(OLD.*),akeys(fk));
     RETURN NEW;
END; $$;


SET default_tablespace = '';

SET default_with_oids = false;


CREATE TABLE _report_editor (
    report character varying NOT NULL,
    username character varying NOT NULL
);



COMMENT ON TABLE _report_editor IS 'Users who have permissions to make changes to a given report.';



COMMENT ON COLUMN _report_editor.report IS 'The identifier of the report.';



COMMENT ON COLUMN _report_editor.username IS 'The name of the user.';



CREATE TABLE _report_viewer (
    report character varying NOT NULL,
    username character varying NOT NULL
);



COMMENT ON TABLE _report_viewer IS 'Users who have permission to view non-public reports.';



COMMENT ON COLUMN _report_viewer.report IS 'The identifier of the report.';



COMMENT ON COLUMN _report_viewer.username IS 'The name of the user.';



CREATE TABLE activity (
    identifier character varying NOT NULL,
    data_usage character varying,
    methodology character varying,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    duration interval,
    computing_environment character varying,
    output_artifacts character varying,
    software character varying,
    visualization_software character varying,
    notes character varying,
    CONSTRAINT ck_activity_identifer CHECK (((identifier)::text ~ '[a-z0-9_-]+'::text)),
    CONSTRAINT ck_activity_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE activity IS 'An activity is a process that occurs over a period of time, and may be associated with a pair of publications.';



COMMENT ON COLUMN activity.identifier IS 'A globally unique identifier for this activity.';



COMMENT ON COLUMN activity.data_usage IS 'A description of the way in which input data were used for this activity.';



COMMENT ON COLUMN activity.methodology IS 'A detailed description of the procedure.';



COMMENT ON COLUMN activity.start_time IS 'The time at which this activity began.';



COMMENT ON COLUMN activity.end_time IS 'The time at which this activity ended.';



COMMENT ON COLUMN activity.duration IS 'The amount of time taken for this activity.';



COMMENT ON COLUMN activity.computing_environment IS 'Operating systems and versions used to perform this activity';



COMMENT ON COLUMN activity.output_artifacts IS 'Files/data products generated by this activity.';



COMMENT ON COLUMN activity.software IS 'Primary software (with version) used.';



COMMENT ON COLUMN activity.visualization_software IS 'Primary visualization software used.';



COMMENT ON COLUMN activity.notes IS 'Other information about this activity which might be useful for traceability or reproducability.';



CREATE TABLE "array" (
    identifier character varying NOT NULL,
    rows_in_header integer DEFAULT 0,
    rows character varying[],
    CONSTRAINT array_dimensions CHECK ((array_ndims(rows) = 2)),
    CONSTRAINT ck_array_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE "array" IS 'An array is an n-dimensional grid of data, and may be associated with a table.';



COMMENT ON COLUMN "array".identifier IS 'A globally unique identifier for this array, such as a UUID.';



COMMENT ON COLUMN "array".rows_in_header IS 'The number of rows in the header of this array.';



COMMENT ON COLUMN "array".rows IS 'The data in this array.';



CREATE TABLE array_table_map (
    array_identifier character varying NOT NULL,
    table_identifier character varying NOT NULL,
    report_identifier character varying NOT NULL
);



COMMENT ON TABLE array_table_map IS 'Arrays and tables have a many-to-many relationship.';



COMMENT ON COLUMN array_table_map.array_identifier IS 'The array.';



COMMENT ON COLUMN array_table_map.table_identifier IS 'The table.';



COMMENT ON COLUMN array_table_map.report_identifier IS 'The report associated with the table.';



CREATE TABLE article (
    identifier character varying NOT NULL,
    title character varying,
    doi character varying,
    year integer,
    journal_identifier character varying NOT NULL,
    journal_vol character varying,
    journal_pages character varying,
    url character varying,
    notes character varying,
    CONSTRAINT article_doi_check CHECK (((doi)::text ~ '^10.[[:print:]]+/[[:print:]]+$'::text)),
    CONSTRAINT article_identifier_check CHECK ((((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)) OR ((identifier)::text ~ '^10.[[:print:]]+/[[:print:]]+$'::text)))
);



COMMENT ON TABLE article IS 'Articles are publications in peer reviewed journals, and generally have DOIs.';



COMMENT ON COLUMN article.identifier IS 'The identifier : this should be the DOI, if there is one.';



COMMENT ON COLUMN article.title IS 'The title of the article (source: crossref.org).';



COMMENT ON COLUMN article.doi IS 'The digital object identifier for the article.';



COMMENT ON COLUMN article.year IS 'The year of publication.';



COMMENT ON COLUMN article.journal_identifier IS 'The GCIS identifier for the journal.';



COMMENT ON COLUMN article.journal_vol IS 'The volume of the journal in which the article appears (source: crossref.org)';



COMMENT ON COLUMN article.journal_pages IS 'The pages of the journal on which the article appears (source: crossref.org)';



COMMENT ON COLUMN article.url IS 'A URL for the article (not necessary if there is a DOI).';



COMMENT ON COLUMN article.notes IS 'Notes about this entry.';



CREATE TABLE book (
    identifier character varying NOT NULL,
    title character varying NOT NULL,
    isbn character varying,
    year numeric,
    publisher character varying,
    number_of_pages numeric,
    url character varying,
    in_library boolean,
    topic character varying,
    CONSTRAINT ck_book_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE book IS 'Entries in this table are publications classified as books.  They should have ISBN numbers. ';



COMMENT ON COLUMN book.identifier IS 'A globally unique identifier for this book.';



COMMENT ON COLUMN book.title IS 'The title of the book';



COMMENT ON COLUMN book.isbn IS 'The 10 or 13 digit ISBN number for this book.';



COMMENT ON COLUMN book.year IS 'The year of publication.';



COMMENT ON COLUMN book.publisher IS 'The name of the publisher.';



COMMENT ON COLUMN book.number_of_pages IS 'The number of pages in the book.';



COMMENT ON COLUMN book.url IS 'A url for a landing page for this book, or for the book itself, if it is available online.';



COMMENT ON COLUMN book.in_library IS 'Whether or not this book is available in the USGCRP resources library.';



COMMENT ON COLUMN book.topic IS 'A brief free form comma-separated list of topics associated with this book.';



CREATE TABLE chapter (
    identifier character varying NOT NULL,
    title character varying,
    report_identifier character varying NOT NULL,
    number integer,
    url character varying,
    sort_key integer,
    doi character varying,
    CONSTRAINT ck_chapter_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE chapter IS 'A chapter is part of a report.';



COMMENT ON COLUMN chapter.identifier IS 'A descriptive identifier for this chapter';



COMMENT ON COLUMN chapter.title IS 'The title.';



COMMENT ON COLUMN chapter.report_identifier IS 'The report containing this chapter.';



COMMENT ON COLUMN chapter.number IS 'The numeric chapter number.';



COMMENT ON COLUMN chapter.url IS 'The URL for a landing page for this chapter.';



COMMENT ON COLUMN chapter.sort_key IS 'A key used to order this chapter within a report.';



COMMENT ON COLUMN chapter.doi IS 'A digital object identifier for this chapter.';



CREATE TABLE context (
    lexicon_identifier character varying NOT NULL,
    identifier character varying NOT NULL,
    version character varying DEFAULT ''::character varying NOT NULL,
    description character varying,
    url character varying,
    CONSTRAINT context_identifier_check CHECK (((identifier)::text ~ similar_escape('[a-zA-Z0-9:_-]+'::text, NULL::text))),
    CONSTRAINT context_version_check CHECK (((version)::text ~ similar_escape('[a-z0-9_\.-]*'::text, NULL::text)))
);



COMMENT ON TABLE context IS 'A context is a subset of terms within a lexicon.';



COMMENT ON COLUMN context.lexicon_identifier IS 'The lexicon associated with this context.';



COMMENT ON COLUMN context.identifier IS 'A brief descriptive identifier for this context.';



COMMENT ON COLUMN context.version IS 'The version of this context (optional).';



COMMENT ON COLUMN context.description IS 'A description of the context.';



COMMENT ON COLUMN context.url IS 'A url for further information.';



CREATE TABLE contributor (
    id integer NOT NULL,
    person_id integer,
    role_type_identifier character varying NOT NULL,
    organization_identifier character varying,
    CONSTRAINT ck_person_org CHECK (((person_id IS NOT NULL) OR (organization_identifier IS NOT NULL)))
);



COMMENT ON TABLE contributor IS 'A contributor is an organization, a role, and optionally a person.';



COMMENT ON COLUMN contributor.id IS 'An opaque numeric identifier for this contributor.';



COMMENT ON COLUMN contributor.person_id IS 'The person (optional).';



COMMENT ON COLUMN contributor.role_type_identifier IS 'The role.';



COMMENT ON COLUMN contributor.organization_identifier IS 'The organization.';



CREATE SEQUENCE contributor_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE contributor_id_seq OWNED BY contributor.id;



CREATE TABLE country (
    code character varying(2) NOT NULL,
    name character varying
);



COMMENT ON TABLE country IS 'A list of countries used in GCIS.';



COMMENT ON COLUMN country.code IS 'Two letter code (ISO 3166-1 alpha-2)';



COMMENT ON COLUMN country.name IS 'Country name.';



CREATE TABLE dataset (
    identifier character varying NOT NULL,
    name character varying,
    type character varying,
    version character varying,
    description character varying,
    native_id character varying,
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
    spatial_res character varying,
    doi character varying,
    release_dt timestamp without time zone,
    publication_year integer,
    attributes character varying,
    variables character varying,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    lat_min numeric,
    lat_max numeric,
    lon_min numeric,
    lon_max numeric,
    description_attribution character varying,
    temporal_resolution character varying,
    CONSTRAINT ck_dataset_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text))),
    CONSTRAINT ck_year CHECK (((publication_year > 1800) AND (publication_year < 9999))),
    CONSTRAINT dataset_doi_check CHECK (((doi)::text ~ '^10.[[:print:]]+/[[:print:]]+$'::text))
);



COMMENT ON TABLE dataset IS 'Datasets are arbitrary collections of data.  They are a type of publication and may be associated with other publications.';



COMMENT ON COLUMN dataset.identifier IS 'A globally unique identifier for this dataset.  This may be a composite identifier derived from external identifier or publications associated with this dataset.';



COMMENT ON COLUMN dataset.name IS 'A brief descriptive name.';



COMMENT ON COLUMN dataset.type IS 'A free form type for this dataset.';



COMMENT ON COLUMN dataset.version IS 'The version.';



COMMENT ON COLUMN dataset.description IS 'A narrative description of this dataset.  If the description is a direct quote available at a URL, put that URL into description_attribution.';



COMMENT ON COLUMN dataset.native_id IS 'The identifier for this dataset given by the producer or archive for the dataset.';



COMMENT ON COLUMN dataset.access_dt IS 'The data on which this dataset was accessed.';



COMMENT ON COLUMN dataset.url IS 'A URL for a landing page.';



COMMENT ON COLUMN dataset.data_qualifier IS 'Assumptions or qualifying statements about this data.';



COMMENT ON COLUMN dataset.scale IS 'If the data has been scaled, describe that here.';



COMMENT ON COLUMN dataset.spatial_ref_sys IS 'The spatial reference system.';



COMMENT ON COLUMN dataset.cite_metadata IS 'The preferred way to cite this dataset.';



COMMENT ON COLUMN dataset.scope IS 'The scope of the data.';



COMMENT ON COLUMN dataset.spatial_extent IS 'Brief description of the spatial extent, which corresponds to lat_min/lat_max, lon_min/lon_max';



COMMENT ON COLUMN dataset.temporal_extent IS 'Brief description of the temporal extent, which corresponds to start_time/end_time';



COMMENT ON COLUMN dataset.vertical_extent IS 'A brief description of the vertical extent.';



COMMENT ON COLUMN dataset.processing_level IS 'The processessing level, if applicable.';



COMMENT ON COLUMN dataset.spatial_res IS 'The spatial resolution.';



COMMENT ON COLUMN dataset.doi IS 'A digital object identifier.';



COMMENT ON COLUMN dataset.release_dt IS 'The date on which this dataset was released.';



COMMENT ON COLUMN dataset.publication_year IS 'The date on which this dataset was initially published.';



COMMENT ON COLUMN dataset.attributes IS 'Free form comma separated attributes for this dataset.';



COMMENT ON COLUMN dataset.variables IS 'Variables represented by this dataset.';



COMMENT ON COLUMN dataset.start_time IS 'The beginning of the temporal extent.';



COMMENT ON COLUMN dataset.end_time IS 'The end of the temporal extent.';



COMMENT ON COLUMN dataset.lat_min IS 'The southernmost latitude in the bounding box for this dataset.';



COMMENT ON COLUMN dataset.lat_max IS 'The nothernmost latitude in the bounding box for this dataset.';



COMMENT ON COLUMN dataset.lon_min IS 'The westernmost longitude in the bounding box for this dataset.';



COMMENT ON COLUMN dataset.lon_max IS 'The eastermost longitude in the bounding box for this dataset.';



COMMENT ON COLUMN dataset.description_attribution IS 'A URL which contains a description of this dataset.';



COMMENT ON COLUMN dataset.temporal_resolution IS 'The temporal resolution (daily, monthly, etc.).';



CREATE TABLE exterm (
    term character varying NOT NULL,
    context character varying NOT NULL,
    lexicon_identifier character varying NOT NULL,
    gcid character varying NOT NULL,
    CONSTRAINT ck_gcid CHECK ((length((gcid)::text) > 0)),
    CONSTRAINT exterm_gcid_check CHECK (((gcid)::text ~ similar_escape('[a-z0-9_/-]+'::text, NULL::text)))
);



COMMENT ON TABLE exterm IS 'External terms which can be mapped to GCIS identifiers.';



COMMENT ON COLUMN exterm.term IS 'The term itself.';



COMMENT ON COLUMN exterm.context IS 'A brief identifier for the context of this term.';



COMMENT ON COLUMN exterm.lexicon_identifier IS 'The lexicon associated with this term.';



COMMENT ON COLUMN exterm.gcid IS 'The GCIS identifier (URI) to which this term is mapped.';



CREATE TABLE figure (
    identifier character varying NOT NULL,
    chapter_identifier character varying,
    title character varying,
    caption character varying,
    attributes character varying,
    time_start timestamp(3) without time zone,
    time_end timestamp(3) without time zone,
    lat_max character varying,
    lat_min character varying,
    lon_max character varying,
    lon_min character varying,
    usage_limits character varying,
    submission_dt timestamp(3) without time zone,
    create_dt timestamp(3) without time zone,
    source_citation character varying,
    ordinal integer,
    report_identifier character varying NOT NULL,
    url character varying,
    CONSTRAINT ck_figure_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE figure IS 'A figure appears in a report and may consist of one or more images.';



COMMENT ON COLUMN figure.identifier IS 'A descriptive identifier for this figure.';



COMMENT ON COLUMN figure.chapter_identifier IS 'The chapter in which this figure appears.';



COMMENT ON COLUMN figure.title IS 'The short title, if any.';



COMMENT ON COLUMN figure.caption IS 'The figure caption.';



COMMENT ON COLUMN figure.attributes IS 'A free form list of attributes for this figure.';



COMMENT ON COLUMN figure.time_start IS 'The start of the spatial extent represtented by this figure.';



COMMENT ON COLUMN figure.time_end IS 'The end of the spatial extent represtented by this figure.';



COMMENT ON COLUMN figure.lat_max IS 'The nothernmost latitude in the bounding box for this figure.';



COMMENT ON COLUMN figure.lat_min IS 'The southernmost latitude in the bounding box for this figure.';



COMMENT ON COLUMN figure.lon_max IS 'The eastermost longitude in the bounding box for this figure.';



COMMENT ON COLUMN figure.lon_min IS 'The westernmost longitude in the bounding box for this figure.';



COMMENT ON COLUMN figure.usage_limits IS 'Copyright restrictions describing how this figure may be used.';



COMMENT ON COLUMN figure.submission_dt IS 'The date on which this image was submitted.';



COMMENT ON COLUMN figure.create_dt IS 'The date on which this image was created.';



COMMENT ON COLUMN figure.source_citation IS 'Text describing the source of this figure.';



COMMENT ON COLUMN figure.ordinal IS 'The numeric position of this figure within a chapter.';



COMMENT ON COLUMN figure.report_identifier IS 'The report associated with this figure';



COMMENT ON COLUMN figure.url IS 'A URL for a landing page for this figure.';



CREATE TABLE file (
    file character varying NOT NULL,
    identifier character varying NOT NULL,
    thumbnail character varying,
    mime_type character varying NOT NULL,
    sha1 character varying,
    size integer,
    location character varying,
    landing_page character varying,
    CONSTRAINT ck_file_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE file IS 'Files are distinct downloadable entities which may be associated with publications.';



COMMENT ON COLUMN file.file IS 'The URI for this file (relative to /assets/ or to the location)';



COMMENT ON COLUMN file.identifier IS 'A globally unique identifier for this file (a UUID).';



COMMENT ON COLUMN file.thumbnail IS 'The location of a thumbnail version of this file (relative to /assets/)';



COMMENT ON COLUMN file.mime_type IS 'The MIME Type (RFC 2046).';



COMMENT ON COLUMN file.sha1 IS 'A SHA1 hash of the contents of this file.';



COMMENT ON COLUMN file.size IS 'The number of bytes in the file.';



COMMENT ON COLUMN file.location IS 'The host for this file, if it is outside of GCIS.';



COMMENT ON COLUMN file.landing_page IS 'A URL for the landing page for this file.';



CREATE SEQUENCE file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE file_id_seq OWNED BY file.identifier;



CREATE TABLE finding (
    identifier character varying NOT NULL,
    chapter_identifier character varying,
    statement character varying,
    ordinal integer,
    report_identifier character varying NOT NULL,
    process character varying,
    evidence character varying,
    uncertainties character varying,
    confidence character varying,
    url character varying,
    CONSTRAINT ck_finding_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE finding IS 'A finding is associated with a report and optionally a chapter.';



COMMENT ON COLUMN finding.identifier IS 'A descriptive identifier for this finding.';



COMMENT ON COLUMN finding.chapter_identifier IS 'The chapter containing this finding.';



COMMENT ON COLUMN finding.statement IS 'The statement of the finding.';



COMMENT ON COLUMN finding.ordinal IS 'The numeric position of this finding with a chapter (or report).';



COMMENT ON COLUMN finding.report_identifier IS 'The report associated with this finding.';



COMMENT ON COLUMN finding.process IS 'The process for developing this finding.';



COMMENT ON COLUMN finding.evidence IS 'A description of the evidence base.';



COMMENT ON COLUMN finding.uncertainties IS 'A description of the uncertainties.';



COMMENT ON COLUMN finding.confidence IS 'An assessment of the confidence in this finding based on the evidence.';



COMMENT ON COLUMN finding.url IS 'A URL for a landing page for this finding.';



CREATE TABLE gcmd_keyword (
    identifier character varying NOT NULL,
    parent_identifier character varying,
    label character varying,
    definition character varying
);



COMMENT ON TABLE gcmd_keyword IS 'Keywords from the Global Change Master Directory <http://gcmd.nasa.gov/learn/keyword_list.html>.';



COMMENT ON COLUMN gcmd_keyword.identifier IS 'The UUID for this keyword.';



COMMENT ON COLUMN gcmd_keyword.parent_identifier IS 'The UUID for the parent keyword.';



COMMENT ON COLUMN gcmd_keyword.label IS 'The brief label for this keyword.';



COMMENT ON COLUMN gcmd_keyword.definition IS 'The definition.';



CREATE TABLE generic (
    identifier character varying NOT NULL,
    attrs hstore,
    CONSTRAINT ck_generic_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE generic IS 'Generic publications, not covered by other GCIS publication types.';



COMMENT ON COLUMN generic.identifier IS 'A globally unique identifier (UUID)';



COMMENT ON COLUMN generic.attrs IS 'Arbitray attributes and values for this generic publication.';



CREATE TABLE image (
    identifier character varying NOT NULL,
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
    usage_limits character varying,
    submission_dt timestamp(3) without time zone,
    create_dt timestamp(3) without time zone,
    url character varying,
    CONSTRAINT ck_image_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE image IS 'An image may be associated with multiple figures, may have provenance and other attributes distinct from that of a parent figure.';



COMMENT ON COLUMN image.identifier IS 'A globally unique identifier (UUID).';



COMMENT ON COLUMN image."position" IS 'A description of where this image is within other figures.';



COMMENT ON COLUMN image.title IS 'A title for this image.';



COMMENT ON COLUMN image.description IS 'An optional description of this image.';



COMMENT ON COLUMN image.attributes IS 'Comma separated free form attributes of this image.';



COMMENT ON COLUMN image.time_start IS 'The start of the spatial extent represtented by this image.';



COMMENT ON COLUMN image.time_end IS 'The end of the spatial extent represtented by this image.';



COMMENT ON COLUMN image.lat_max IS 'The nothernmost latitude in the bounding box for this image.';



COMMENT ON COLUMN image.lat_min IS 'The southernmost latitude in the bounding box for this image.';



COMMENT ON COLUMN image.lon_max IS 'The eastermost longitude in the bounding box for this image.';



COMMENT ON COLUMN image.lon_min IS 'The westernmost longitude in the bounding box for this image.';



COMMENT ON COLUMN image.usage_limits IS 'Copyright restrictions describing how this image may be used.';



COMMENT ON COLUMN image.url IS 'A landing page for this image.';



CREATE TABLE image_figure_map (
    image_identifier character varying NOT NULL,
    figure_identifier character varying NOT NULL,
    report_identifier character varying NOT NULL
);



COMMENT ON TABLE image_figure_map IS 'A figure can have many images and vice versa.';



COMMENT ON COLUMN image_figure_map.image_identifier IS 'The image.';



COMMENT ON COLUMN image_figure_map.figure_identifier IS 'The figure.';



COMMENT ON COLUMN image_figure_map.report_identifier IS 'The report containing the figure.';



CREATE TABLE instrument (
    identifier character varying NOT NULL,
    name character varying NOT NULL,
    description character varying,
    description_attribution character varying,
    CONSTRAINT instrument_identifier_check CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE instrument IS 'An instrument is used for measurement.';



COMMENT ON COLUMN instrument.identifier IS 'A descriptive identifier for this instrument.';



COMMENT ON COLUMN instrument.name IS 'A brief name for this instrument.';



COMMENT ON COLUMN instrument.description IS 'A description of this instrument.';



COMMENT ON COLUMN instrument.description_attribution IS 'A URL which contains the description of this instrument.';



CREATE TABLE instrument_instance (
    platform_identifier character varying NOT NULL,
    instrument_identifier character varying NOT NULL,
    location character varying
);



COMMENT ON TABLE instrument_instance IS 'An instrument instance is the association of an instrument with a platform.';



COMMENT ON COLUMN instrument_instance.platform_identifier IS 'The platform.';



COMMENT ON COLUMN instrument_instance.instrument_identifier IS 'The instrument.';



COMMENT ON COLUMN instrument_instance.location IS 'The location of the instrument on the platform.';



CREATE TABLE instrument_measurement (
    platform_identifier character varying NOT NULL,
    instrument_identifier character varying NOT NULL,
    dataset_identifier character varying NOT NULL
);



COMMENT ON TABLE instrument_measurement IS 'An instrument measurement is a way of associating an instrument instance with a dataset.';



COMMENT ON COLUMN instrument_measurement.platform_identifier IS 'The platform of the instrument.';



COMMENT ON COLUMN instrument_measurement.instrument_identifier IS 'The instrument.';



COMMENT ON COLUMN instrument_measurement.dataset_identifier IS 'The dataset.';



CREATE TABLE journal (
    identifier character varying NOT NULL,
    title character varying,
    publisher character varying,
    country character varying,
    url character varying,
    notes character varying,
    print_issn issn,
    online_issn issn,
    CONSTRAINT ck_journal_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text))),
    CONSTRAINT has_issn CHECK (((print_issn IS NOT NULL) OR (online_issn IS NOT NULL)))
);



COMMENT ON TABLE journal IS 'A journal is a peer reviewed publication which contains articles.';



COMMENT ON COLUMN journal.identifier IS 'A descriptive identifier for this journal.';



COMMENT ON COLUMN journal.title IS 'The title of the journal (source: crossref.org)';



COMMENT ON COLUMN journal.publisher IS 'The publisher of the journal.';



COMMENT ON COLUMN journal.country IS 'The country of publication.';



COMMENT ON COLUMN journal.url IS 'A URL for the landing page for this journal.';



CREATE TABLE lexicon (
    identifier character varying NOT NULL,
    description character varying,
    url character varying,
    CONSTRAINT lexicon_identifier_check CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE lexicon IS 'A lexicon is a list of terms which correspond to GCIS identifiers.';



COMMENT ON COLUMN lexicon.identifier IS 'A brief descriptive identifier for this lexicon.';



COMMENT ON COLUMN lexicon.description IS 'A description of the lexicon, possibly including the organization associated with it.';



COMMENT ON COLUMN lexicon.url IS 'A url for further information.';



CREATE TABLE methodology (
    activity_identifier character varying NOT NULL,
    publication_id integer NOT NULL
);



COMMENT ON TABLE methodology IS 'A methodology is a publication associated with an activity';



COMMENT ON COLUMN methodology.activity_identifier IS 'The activity.';



COMMENT ON COLUMN methodology.publication_id IS 'The publication.';



CREATE TABLE model (
    identifier character varying NOT NULL,
    project_identifier character varying,
    name character varying,
    version character varying,
    reference_url character varying NOT NULL,
    website character varying,
    description character varying,
    description_attribution character varying
);



COMMENT ON TABLE model IS 'Models may be associated with scenarios, model runs, and projects.';



COMMENT ON COLUMN model.identifier IS 'A unique descriptive identifier.';



COMMENT ON COLUMN model.project_identifier IS 'A project associated with this model.';



COMMENT ON COLUMN model.name IS 'A brief name.';



COMMENT ON COLUMN model.version IS 'A version.';



COMMENT ON COLUMN model.reference_url IS 'A URL to find publiations with details about this model.';



COMMENT ON COLUMN model.website IS 'A public website with high level descriptions about this model.';



COMMENT ON COLUMN model.description IS 'A description.';



COMMENT ON COLUMN model.description_attribution IS 'A URL containing the description of this model.';



CREATE TABLE model_run (
    identifier character varying NOT NULL,
    doi character varying,
    model_identifier character varying NOT NULL,
    scenario_identifier character varying NOT NULL,
    spatial_resolution character varying NOT NULL,
    range_start date NOT NULL,
    range_end date NOT NULL,
    sequence integer DEFAULT 1 NOT NULL,
    sequence_description character varying,
    activity_identifier character varying,
    project_identifier character varying,
    time_resolution interval,
    CONSTRAINT model_run_identifier_check CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE model_run IS 'A model run associates a model with a scenario and a project.';



COMMENT ON COLUMN model_run.identifier IS 'A unique identifier for this model run.';



COMMENT ON COLUMN model_run.doi IS 'A digital object identifier.';



COMMENT ON COLUMN model_run.model_identifier IS 'The model.';



COMMENT ON COLUMN model_run.scenario_identifier IS 'The scenario.';



COMMENT ON COLUMN model_run.spatial_resolution IS 'The spatialr resolution of this run.';



COMMENT ON COLUMN model_run.range_start IS 'The start of time range convered by this model';



COMMENT ON COLUMN model_run.range_end IS 'The end of time range convered by this model';



COMMENT ON COLUMN model_run.sequence IS 'An index distinguishing this run from other runs with similar parameters.';



COMMENT ON COLUMN model_run.sequence_description IS 'A description of how this run differs from others with similar parameters.';



COMMENT ON COLUMN model_run.activity_identifier IS 'An activity associated with this model run.';



COMMENT ON COLUMN model_run.project_identifier IS 'A project associated with this model.';



COMMENT ON COLUMN model_run.time_resolution IS 'The temporal resolution of this run.';



CREATE TABLE organization (
    identifier character varying NOT NULL,
    name character varying,
    url character varying,
    country_code character varying,
    organization_type_identifier character varying,
    CONSTRAINT organization_identifier_check CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE organization IS 'An organization is an entity with which people and publications may be associated.';



COMMENT ON COLUMN organization.identifier IS 'A descriptive identifier.';



COMMENT ON COLUMN organization.name IS 'The name.';



COMMENT ON COLUMN organization.url IS 'The URL for the organization.';



COMMENT ON COLUMN organization.country_code IS 'The country with which this organizaion is affiliated.';



COMMENT ON COLUMN organization.organization_type_identifier IS 'The type of organization.';



CREATE TABLE organization_map (
    organization_identifier character varying NOT NULL,
    other_organization_identifier character varying NOT NULL,
    organization_relationship_identifier character varying NOT NULL
);



COMMENT ON TABLE organization_map IS 'Organizations may be associated with other organizations.';



COMMENT ON COLUMN organization_map.organization_identifier IS 'The first organization.';



COMMENT ON COLUMN organization_map.other_organization_identifier IS 'The target.';



COMMENT ON COLUMN organization_map.organization_relationship_identifier IS 'The relationship.';



CREATE TABLE organization_relationship (
    identifier character varying NOT NULL,
    label character varying NOT NULL
);



COMMENT ON TABLE organization_relationship IS 'These are the possible ways in which two organizations may be related.';



COMMENT ON COLUMN organization_relationship.identifier IS 'A descriptive identifier.';



COMMENT ON COLUMN organization_relationship.label IS 'A human readable label.';



CREATE TABLE organization_type (
    identifier character varying NOT NULL
);



COMMENT ON TABLE organization_type IS 'The distinct types of organizations represented.';



COMMENT ON COLUMN organization_type.identifier IS 'A descriptive identifier.';



CREATE TABLE person (
    id integer NOT NULL,
    url character varying,
    orcid character varying,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    middle_name character varying,
    CONSTRAINT ck_orcid CHECK (((orcid)::text ~ similar_escape('\A\d{4}-\d{4}-\d{4}-\d{3}[0-9X]\Z'::text, NULL::text)))
);



COMMENT ON TABLE person IS 'People are stored using opaque numeric identifiers.';



COMMENT ON COLUMN person.id IS 'A unique numeric identifier.';



COMMENT ON COLUMN person.url IS 'A URL with information about this person.';



COMMENT ON COLUMN person.orcid IS 'An ORCID (<http://orcid.org>) for this person.';



COMMENT ON COLUMN person.first_name IS 'The given name of the person.';



COMMENT ON COLUMN person.last_name IS 'The family name of the person.';



COMMENT ON COLUMN person.middle_name IS 'The middle name of the person.';



CREATE SEQUENCE person_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE person_id_seq OWNED BY person.id;



CREATE TABLE platform (
    identifier character varying NOT NULL,
    name character varying NOT NULL,
    description character varying,
    url character varying,
    platform_type_identifier character varying,
    description_attribution character varying,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    CONSTRAINT platform_identifier_check CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE platform IS 'A platform may be associated with one more more instruments.';



COMMENT ON COLUMN platform.identifier IS 'A descriptive identifier for this platform.';



COMMENT ON COLUMN platform.name IS 'A brief name.';



COMMENT ON COLUMN platform.description IS 'A description.';



COMMENT ON COLUMN platform.url IS 'A landing page with information about this platform.';



COMMENT ON COLUMN platform.platform_type_identifier IS 'The type.';



COMMENT ON COLUMN platform.description_attribution IS 'A URL containing the description.';



COMMENT ON COLUMN platform.start_date IS 'The date on which this platform first began operating.';



COMMENT ON COLUMN platform.end_date IS 'The date on which this platform ceased operations.';



CREATE TABLE platform_type (
    identifier character varying NOT NULL
);



COMMENT ON TABLE platform_type IS 'Platforms have a type.';



COMMENT ON COLUMN platform_type.identifier IS 'A descriptive identifier for this type.';



CREATE TABLE project (
    identifier character varying NOT NULL,
    name character varying,
    description character varying,
    description_attribution character varying,
    website character varying
);



COMMENT ON TABLE project IS 'A project may be associated with a collection of models.';



COMMENT ON COLUMN project.identifier IS 'A descriptive identifier.';



COMMENT ON COLUMN project.name IS 'A short name.';



COMMENT ON COLUMN project.description IS 'A description.';



COMMENT ON COLUMN project.description_attribution IS 'A URL containing the description.';



COMMENT ON COLUMN project.website IS 'A website officially assocaited with this project.';



CREATE TABLE publication (
    id integer NOT NULL,
    publication_type_identifier character varying NOT NULL,
    fk hstore NOT NULL
);



COMMENT ON TABLE publication IS 'A publication, similar to an entity, is a generic term for something that has been released to the public.';



COMMENT ON COLUMN publication.id IS 'An opaque numeric identifier';



COMMENT ON COLUMN publication.publication_type_identifier IS 'The type';



COMMENT ON COLUMN publication.fk IS 'Column column names and values of the primary key of this entitiy in its native table.';



CREATE TABLE publication_contributor_map (
    publication_id integer NOT NULL,
    contributor_id integer NOT NULL,
    reference_identifier character varying,
    sort_key integer
);



COMMENT ON TABLE publication_contributor_map IS 'Publications can have one more contributors.';



COMMENT ON COLUMN publication_contributor_map.publication_id IS 'The publication.';



COMMENT ON COLUMN publication_contributor_map.contributor_id IS 'The contributor.';



COMMENT ON COLUMN publication_contributor_map.reference_identifier IS 'A reference which makes the association between the publicaton and the contributor.';



COMMENT ON COLUMN publication_contributor_map.sort_key IS 'A sort key for this entry.';



CREATE TABLE publication_file_map (
    publication_id integer NOT NULL,
    file_identifier character varying NOT NULL
);



COMMENT ON TABLE publication_file_map IS 'Publications may have zero or more files.  And vice versa.';



COMMENT ON COLUMN publication_file_map.publication_id IS 'A publication.';



COMMENT ON COLUMN publication_file_map.file_identifier IS 'A file.';



CREATE TABLE publication_gcmd_keyword_map (
    publication_id integer NOT NULL,
    gcmd_keyword_identifier character varying NOT NULL
);



COMMENT ON TABLE publication_gcmd_keyword_map IS 'Publications can have zero or more keywords.  And vice versa.';



COMMENT ON COLUMN publication_gcmd_keyword_map.publication_id IS 'A publication.';



COMMENT ON COLUMN publication_gcmd_keyword_map.gcmd_keyword_identifier IS 'A keyword.';



CREATE SEQUENCE publication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE publication_id_seq OWNED BY publication.id;



CREATE TABLE publication_map (
    child integer NOT NULL,
    relationship character varying NOT NULL,
    parent integer NOT NULL,
    note character varying,
    activity_identifier character varying
);



COMMENT ON TABLE publication_map IS 'Publications can be related to other publications.';



COMMENT ON COLUMN publication_map.child IS 'The child publication.';



COMMENT ON COLUMN publication_map.relationship IS 'The relationship, in the form ontology:term.';



COMMENT ON COLUMN publication_map.parent IS 'The parent publication.';



COMMENT ON COLUMN publication_map.note IS 'A narrative comment about this relationship.';



COMMENT ON COLUMN publication_map.activity_identifier IS 'XXX';



CREATE TABLE publication_reference_map (
    publication_id integer NOT NULL,
    reference_identifier character varying NOT NULL
);



COMMENT ON TABLE publication_reference_map IS 'A map from publications to references.';



COMMENT ON COLUMN publication_reference_map.publication_id IS 'The publication.';



COMMENT ON COLUMN publication_reference_map.reference_identifier IS 'The reference.';



CREATE TABLE publication_region_map (
    publication_id integer NOT NULL,
    region_identifier character varying NOT NULL
);



COMMENT ON TABLE publication_region_map IS 'Publications can have many regions and vice versa.';



COMMENT ON COLUMN publication_region_map.publication_id IS 'A publication.';



COMMENT ON COLUMN publication_region_map.region_identifier IS 'A region.';



CREATE TABLE publication_type (
    identifier character varying NOT NULL,
    "table" character varying
);



COMMENT ON TABLE publication_type IS 'Publications have types which correspond to database tables.';



COMMENT ON COLUMN publication_type.identifier IS 'A descriptive type.';



COMMENT ON COLUMN publication_type."table" IS 'The database table.';



CREATE TABLE reference (
    identifier character varying NOT NULL,
    attrs hstore,
    child_publication_id integer,
    CONSTRAINT ck_reference_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE reference IS 'A reference is a bibliographic entry.  It relates two publications.';



COMMENT ON COLUMN reference.identifier IS 'A unique identifier (a UUID).';



COMMENT ON COLUMN reference.attrs IS 'Arbitrary name-value pairs for this reference.';



COMMENT ON COLUMN reference.child_publication_id IS 'The publication to which this reference refers.';



CREATE TABLE region (
    identifier character varying NOT NULL,
    label character varying NOT NULL,
    description character varying,
    CONSTRAINT ck_region_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE region IS 'A region is a geographical area.';



COMMENT ON COLUMN region.identifier IS 'A descriptive identifier.';



COMMENT ON COLUMN region.label IS 'A human readable label.';



COMMENT ON COLUMN region.description IS 'A description.';



CREATE TABLE relationship (
    identifier character varying NOT NULL,
    description character varying
);



COMMENT ON TABLE relationship IS 'The blessed semantic web relationships.';



COMMENT ON COLUMN relationship.identifier IS 'A fully qualified semantic web relationship.';



COMMENT ON COLUMN relationship.description IS 'A description of the relationship.';



CREATE TABLE report (
    identifier character varying NOT NULL,
    title character varying NOT NULL,
    url character varying,
    doi character varying,
    _public boolean DEFAULT true,
    report_type_identifier character varying DEFAULT 'report'::character varying NOT NULL,
    summary character varying,
    frequency interval,
    publication_year integer,
    topic character varying,
    in_library boolean,
    contact_note character varying,
    contact_email character varying,
    CONSTRAINT ck_report_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text))),
    CONSTRAINT ck_report_pubyear CHECK (((publication_year > 0) AND (publication_year < 9999))),
    CONSTRAINT report_doi_check CHECK (((doi)::text ~ '^10.[[:print:]]+/[[:print:]]+$'::text))
);



COMMENT ON TABLE report IS 'A report is a publication that may have chapters, figures, findings, and tables.';



COMMENT ON COLUMN report.identifier IS 'A descriptive identifier.';



COMMENT ON COLUMN report.title IS 'The title.';



COMMENT ON COLUMN report.url IS 'A url for a landing page.';



COMMENT ON COLUMN report.doi IS 'A digital object identifier.';



COMMENT ON COLUMN report._public IS 'Indicates that this report is publically readable.';



COMMENT ON COLUMN report.report_type_identifier IS 'The type of this report.';



COMMENT ON COLUMN report.summary IS 'A brief summary';



COMMENT ON COLUMN report.frequency IS 'If this is a periodic report, how often it is released.';



COMMENT ON COLUMN report.publication_year IS 'The year of publication.';



COMMENT ON COLUMN report.topic IS 'A brief free form comma-separated list of topics associated with this report.';



COMMENT ON COLUMN report.in_library IS 'Whether or not this report is available in the USGCRP resources library.';



COMMENT ON COLUMN report.contact_note IS 'A note about contacting someone about this report.  Phrases [in brackets] in this note will become links to the contact_email.';



COMMENT ON COLUMN report.contact_email IS 'A contact email address for this report.';



CREATE TABLE report_type (
    identifier character varying NOT NULL
);



COMMENT ON TABLE report_type IS 'A list of report types.';



COMMENT ON COLUMN report_type.identifier IS 'A descriptive identifer.';



CREATE TABLE role_type (
    identifier character varying NOT NULL,
    label character varying NOT NULL,
    sort_key integer,
    comment character varying
);



COMMENT ON TABLE role_type IS 'A list of roles that contributors may have.';



COMMENT ON COLUMN role_type.identifier IS 'A descriptive identifier.';



COMMENT ON COLUMN role_type.label IS 'A human readable label.';



COMMENT ON COLUMN role_type.sort_key IS 'A key for sorting contributors of this type.';



COMMENT ON COLUMN role_type.comment IS 'A description of this role.';



CREATE TABLE scenario (
    identifier character varying NOT NULL,
    name character varying,
    description character varying,
    description_attribution character varying,
    CONSTRAINT scenario_identifier_check CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE scenario IS 'A scenario may be associated with a model via a model run.';



COMMENT ON COLUMN scenario.identifier IS 'A desciptive identifier.';



COMMENT ON COLUMN scenario.name IS 'A brief name.';



COMMENT ON COLUMN scenario.description IS 'A description.';



COMMENT ON COLUMN scenario.description_attribution IS 'A URL containing the description.';



CREATE TABLE "table" (
    identifier character varying NOT NULL,
    report_identifier character varying NOT NULL,
    chapter_identifier character varying,
    ordinal integer,
    title character varying,
    caption character varying,
    url character varying,
    CONSTRAINT ck_table_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE "table" IS 'A table is in a report, and may contain one or more arrays.';



COMMENT ON COLUMN "table".identifier IS 'A desciptive identifier.';



COMMENT ON COLUMN "table".report_identifier IS 'The report.';



COMMENT ON COLUMN "table".chapter_identifier IS 'The chapter containing this table.';



COMMENT ON COLUMN "table".ordinal IS 'The numeric postiion of this table within the chapter.';



COMMENT ON COLUMN "table".title IS 'The title of the table.';



COMMENT ON COLUMN "table".caption IS 'The caption for the table.';



COMMENT ON COLUMN "table".url IS 'A URL for a landing page for this table.';



CREATE TABLE term (
    identifier character varying DEFAULT uuid_generate_v1() NOT NULL,
    lexicon_identifier character varying NOT NULL,
    context_identifier character varying NOT NULL,
    context_version character varying DEFAULT ''::character varying,
    term character varying NOT NULL,
    is_root boolean DEFAULT false,
    description character varying,
    url character varying
);



COMMENT ON TABLE term IS 'Terms that have a specific lexicon and context.';



COMMENT ON COLUMN term.identifier IS 'A globally unique identifier for this term (a UUID).';



COMMENT ON COLUMN term.lexicon_identifier IS 'The lexicon associated with this term.';



COMMENT ON COLUMN term.context_identifier IS 'The context associated with this term.';



COMMENT ON COLUMN term.context_version IS 'The version of the context associated with this term (optional).';



COMMENT ON COLUMN term.term IS 'The term itself.';



COMMENT ON COLUMN term.is_root IS 'A flag indicating the term is at the top level (eg, no broader term).';



COMMENT ON COLUMN term.description IS 'A description of the term.';



COMMENT ON COLUMN term.url IS 'A url for further information.';



CREATE TABLE term_map (
    term_identifier character varying NOT NULL,
    relationship_identifier character varying NOT NULL,
    gcid character varying NOT NULL,
    description character varying,
    "timestamp" timestamp(3) without time zone DEFAULT now(),
    CONSTRAINT ck_gcid CHECK ((length((gcid)::text) > 0))
);



COMMENT ON TABLE term_map IS 'External terms which can be mapped to GCIS identifiers via a relationship.';



COMMENT ON COLUMN term_map.term_identifier IS 'The term ID (UUID).';



COMMENT ON COLUMN term_map.relationship_identifier IS 'The relationship between the term and the gcid.';



COMMENT ON COLUMN term_map.gcid IS 'The GCIS identifier (URI) to which this term is mapped.';



COMMENT ON COLUMN term_map.description IS 'A description for the GCID (optional).';



COMMENT ON COLUMN term_map."timestamp" IS 'The timestamp this relationship was asserted.';



CREATE TABLE term_rel (
    term_subject character varying NOT NULL,
    relationship_identifier character varying NOT NULL,
    term_object character varying NOT NULL
);



COMMENT ON TABLE term_rel IS 'Expresses how a term is related to another term.';



COMMENT ON COLUMN term_rel.term_subject IS 'The subject term (UUID).';



COMMENT ON COLUMN term_rel.relationship_identifier IS 'The relationship of subject to object.';



COMMENT ON COLUMN term_rel.term_object IS 'The object term (UUID).';



CREATE VIEW vw_gcmd_keyword AS
 SELECT COALESCE(level4.identifier, level3.identifier, level2.identifier, level1.identifier, term.identifier, topic.identifier, category.identifier) AS identifier,
    category.label AS category,
    topic.label AS topic,
    term.label AS term,
    level1.label AS level1,
    level2.label AS level2,
    level3.label AS level3,
    level4.label AS level4
   FROM (((((((gcmd_keyword wrapper
     JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text)))
     JOIN gcmd_keyword topic ON (((topic.parent_identifier)::text = (category.identifier)::text)))
     JOIN gcmd_keyword term ON (((term.parent_identifier)::text = (topic.identifier)::text)))
     JOIN gcmd_keyword level1 ON (((level1.parent_identifier)::text = (term.identifier)::text)))
     JOIN gcmd_keyword level2 ON (((level2.parent_identifier)::text = (level1.identifier)::text)))
     JOIN gcmd_keyword level3 ON (((level3.parent_identifier)::text = (level2.identifier)::text)))
     JOIN gcmd_keyword level4 ON (((level4.parent_identifier)::text = (level3.identifier)::text)))
  WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text))
UNION
 SELECT COALESCE(level3.identifier, level2.identifier, level1.identifier, term.identifier, topic.identifier, category.identifier) AS identifier,
    category.label AS category,
    topic.label AS topic,
    term.label AS term,
    level1.label AS level1,
    level2.label AS level2,
    level3.label AS level3,
    NULL::character varying AS level4
   FROM ((((((gcmd_keyword wrapper
     JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text)))
     JOIN gcmd_keyword topic ON (((topic.parent_identifier)::text = (category.identifier)::text)))
     JOIN gcmd_keyword term ON (((term.parent_identifier)::text = (topic.identifier)::text)))
     JOIN gcmd_keyword level1 ON (((level1.parent_identifier)::text = (term.identifier)::text)))
     JOIN gcmd_keyword level2 ON (((level2.parent_identifier)::text = (level1.identifier)::text)))
     JOIN gcmd_keyword level3 ON (((level3.parent_identifier)::text = (level2.identifier)::text)))
  WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text))
UNION
 SELECT COALESCE(level2.identifier, level1.identifier, term.identifier, topic.identifier, category.identifier) AS identifier,
    category.label AS category,
    topic.label AS topic,
    term.label AS term,
    level1.label AS level1,
    level2.label AS level2,
    NULL::character varying AS level3,
    NULL::character varying AS level4
   FROM (((((gcmd_keyword wrapper
     JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text)))
     JOIN gcmd_keyword topic ON (((topic.parent_identifier)::text = (category.identifier)::text)))
     JOIN gcmd_keyword term ON (((term.parent_identifier)::text = (topic.identifier)::text)))
     JOIN gcmd_keyword level1 ON (((level1.parent_identifier)::text = (term.identifier)::text)))
     JOIN gcmd_keyword level2 ON (((level2.parent_identifier)::text = (level1.identifier)::text)))
  WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text))
UNION
 SELECT COALESCE(level1.identifier, term.identifier, topic.identifier, category.identifier) AS identifier,
    category.label AS category,
    topic.label AS topic,
    term.label AS term,
    level1.label AS level1,
    NULL::character varying AS level2,
    NULL::character varying AS level3,
    NULL::character varying AS level4
   FROM ((((gcmd_keyword wrapper
     JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text)))
     JOIN gcmd_keyword topic ON (((topic.parent_identifier)::text = (category.identifier)::text)))
     JOIN gcmd_keyword term ON (((term.parent_identifier)::text = (topic.identifier)::text)))
     JOIN gcmd_keyword level1 ON (((level1.parent_identifier)::text = (term.identifier)::text)))
  WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text))
UNION
 SELECT COALESCE(term.identifier, topic.identifier, category.identifier) AS identifier,
    category.label AS category,
    topic.label AS topic,
    term.label AS term,
    NULL::character varying AS level1,
    NULL::character varying AS level2,
    NULL::character varying AS level3,
    NULL::character varying AS level4
   FROM (((gcmd_keyword wrapper
     JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text)))
     JOIN gcmd_keyword topic ON (((topic.parent_identifier)::text = (category.identifier)::text)))
     JOIN gcmd_keyword term ON (((term.parent_identifier)::text = (topic.identifier)::text)))
  WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text))
UNION
 SELECT COALESCE(topic.identifier, category.identifier) AS identifier,
    category.label AS category,
    topic.label AS topic,
    NULL::character varying AS term,
    NULL::character varying AS level1,
    NULL::character varying AS level2,
    NULL::character varying AS level3,
    NULL::character varying AS level4
   FROM ((gcmd_keyword wrapper
     JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text)))
     JOIN gcmd_keyword topic ON (((topic.parent_identifier)::text = (category.identifier)::text)))
  WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text))
UNION
 SELECT COALESCE(category.identifier) AS identifier,
    category.label AS category,
    NULL::character varying AS topic,
    NULL::character varying AS term,
    NULL::character varying AS level1,
    NULL::character varying AS level2,
    NULL::character varying AS level3,
    NULL::character varying AS level4
   FROM (gcmd_keyword wrapper
     JOIN gcmd_keyword category ON (((category.parent_identifier)::text = (wrapper.identifier)::text)))
  WHERE (((wrapper.identifier)::text = '1eb0ea0a-312c-4d74-8d42-6f1ad758f999'::text) AND ((wrapper.label)::text = 'Science Keywords'::text));



CREATE TABLE webpage (
    identifier character varying NOT NULL,
    url character varying NOT NULL,
    title character varying,
    access_date timestamp without time zone,
    CONSTRAINT ck_webpage_identifier CHECK (((identifier)::text ~ similar_escape('[a-z0-9_-]+'::text, NULL::text)))
);



COMMENT ON TABLE webpage IS 'A webpage is a type of publication.';



COMMENT ON COLUMN webpage.identifier IS 'A globally identifier (UUID)';



COMMENT ON COLUMN webpage.url IS 'The URL.';



COMMENT ON COLUMN webpage.title IS 'The title of the webpage.';



COMMENT ON COLUMN webpage.access_date IS 'The date on which this webpage was accessed.';



ALTER TABLE ONLY contributor ALTER COLUMN id SET DEFAULT nextval('contributor_id_seq'::regclass);



ALTER TABLE ONLY file ALTER COLUMN identifier SET DEFAULT nextval('file_id_seq'::regclass);



ALTER TABLE ONLY person ALTER COLUMN id SET DEFAULT nextval('person_id_seq'::regclass);



ALTER TABLE ONLY publication ALTER COLUMN id SET DEFAULT nextval('publication_id_seq'::regclass);



ALTER TABLE ONLY _report_editor
    ADD CONSTRAINT _report_editor_pkey PRIMARY KEY (report, username);



ALTER TABLE ONLY _report_viewer
    ADD CONSTRAINT _report_viewer_pkey PRIMARY KEY (report, username);



ALTER TABLE ONLY activity
    ADD CONSTRAINT activity_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY "array"
    ADD CONSTRAINT array_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY array_table_map
    ADD CONSTRAINT array_table_map_pkey PRIMARY KEY (array_identifier, table_identifier, report_identifier);



ALTER TABLE ONLY article
    ADD CONSTRAINT article_doi_key UNIQUE (doi);



ALTER TABLE ONLY article
    ADD CONSTRAINT article_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY book
    ADD CONSTRAINT book_isbn_key UNIQUE (isbn);



ALTER TABLE ONLY book
    ADD CONSTRAINT book_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_pkey PRIMARY KEY (identifier, report_identifier);



ALTER TABLE ONLY context
    ADD CONSTRAINT context_pkey PRIMARY KEY (lexicon_identifier, identifier, version);



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_person_id_role_type_organization_identifier_key UNIQUE (person_id, role_type_identifier, organization_identifier);



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_pkey PRIMARY KEY (id);



ALTER TABLE ONLY country
    ADD CONSTRAINT country_pkey PRIMARY KEY (code);



ALTER TABLE ONLY dataset
    ADD CONSTRAINT dataset_doi UNIQUE (doi);



ALTER TABLE ONLY dataset
    ADD CONSTRAINT dataset_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY exterm
    ADD CONSTRAINT exterm_pkey PRIMARY KEY (lexicon_identifier, context, term);



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_pkey PRIMARY KEY (identifier, report_identifier);



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_report_identifier_chapter_identifier_ordinal_key UNIQUE (report_identifier, chapter_identifier, ordinal);



ALTER TABLE ONLY file
    ADD CONSTRAINT file_file_key UNIQUE (file);



ALTER TABLE ONLY file
    ADD CONSTRAINT file_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY finding
    ADD CONSTRAINT finding_pkey PRIMARY KEY (identifier, report_identifier);



ALTER TABLE ONLY finding
    ADD CONSTRAINT finding_report_identifier_chapter_identifier_ordinal_key UNIQUE (report_identifier, chapter_identifier, ordinal);



ALTER TABLE ONLY gcmd_keyword
    ADD CONSTRAINT gcmd_keyword_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY generic
    ADD CONSTRAINT generic_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY image_figure_map
    ADD CONSTRAINT image_figure_map_pkey PRIMARY KEY (image_identifier, figure_identifier, report_identifier);



ALTER TABLE ONLY image
    ADD CONSTRAINT image_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY image
    ADD CONSTRAINT image_url_key UNIQUE (url);



ALTER TABLE ONLY instrument_instance
    ADD CONSTRAINT instrument_instance_pkey PRIMARY KEY (platform_identifier, instrument_identifier);



ALTER TABLE ONLY instrument_measurement
    ADD CONSTRAINT instrument_measurement_pkey PRIMARY KEY (platform_identifier, instrument_identifier, dataset_identifier);



ALTER TABLE ONLY instrument
    ADD CONSTRAINT instrument_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY journal
    ADD CONSTRAINT journal_new_online_issn_key UNIQUE (online_issn);



ALTER TABLE ONLY journal
    ADD CONSTRAINT journal_new_print_issn_key UNIQUE (print_issn);



ALTER TABLE ONLY journal
    ADD CONSTRAINT journal_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY lexicon
    ADD CONSTRAINT lexicon_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY methodology
    ADD CONSTRAINT methodology_pkey PRIMARY KEY (activity_identifier, publication_id);



ALTER TABLE ONLY model
    ADD CONSTRAINT model_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY model_run
    ADD CONSTRAINT model_run_doi_key UNIQUE (doi);



ALTER TABLE ONLY model_run
    ADD CONSTRAINT model_run_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY model_run
    ADD CONSTRAINT model_run_unique UNIQUE (model_identifier, scenario_identifier, range_start, range_end, sequence, time_resolution);



ALTER TABLE ONLY organization_map
    ADD CONSTRAINT organization_map_pkey PRIMARY KEY (organization_identifier, other_organization_identifier, organization_relationship_identifier);



ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_name_key UNIQUE (name);



ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY organization_relationship
    ADD CONSTRAINT organization_relationship_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY organization_type
    ADD CONSTRAINT organization_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY person
    ADD CONSTRAINT person_orcid_key UNIQUE (orcid);



ALTER TABLE ONLY person
    ADD CONSTRAINT person_pkey PRIMARY KEY (id);



ALTER TABLE ONLY platform
    ADD CONSTRAINT platform_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY platform_type
    ADD CONSTRAINT platform_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY project
    ADD CONSTRAINT project_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY publication_contributor_map
    ADD CONSTRAINT publication_contributor_map_pkey PRIMARY KEY (publication_id, contributor_id);



ALTER TABLE ONLY publication_file_map
    ADD CONSTRAINT publication_file_map_pkey PRIMARY KEY (publication_id, file_identifier);



ALTER TABLE ONLY publication_gcmd_keyword_map
    ADD CONSTRAINT publication_gcmd_keyword_map_pkey PRIMARY KEY (publication_id, gcmd_keyword_identifier);



ALTER TABLE ONLY publication_map
    ADD CONSTRAINT publication_map_pkey PRIMARY KEY (child, relationship, parent);



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_pkey PRIMARY KEY (id);



ALTER TABLE ONLY publication_region_map
    ADD CONSTRAINT publication_region_map_pkey PRIMARY KEY (publication_id, region_identifier);



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_type_fk UNIQUE (publication_type_identifier, fk);



ALTER TABLE ONLY publication_type
    ADD CONSTRAINT publication_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY reference
    ADD CONSTRAINT reference_identifier_child_publication_id_key UNIQUE (identifier, child_publication_id);



ALTER TABLE ONLY reference
    ADD CONSTRAINT reference_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY region
    ADD CONSTRAINT region_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY relationship
    ADD CONSTRAINT relationship_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY report
    ADD CONSTRAINT report_doi_unique UNIQUE (doi);



ALTER TABLE ONLY report
    ADD CONSTRAINT report_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY report_type
    ADD CONSTRAINT report_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY report
    ADD CONSTRAINT report_url_key UNIQUE (url);



ALTER TABLE ONLY role_type
    ADD CONSTRAINT role_type_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY scenario
    ADD CONSTRAINT scenario_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY publication_reference_map
    ADD CONSTRAINT subpubref_pkey PRIMARY KEY (publication_id, reference_identifier);



ALTER TABLE ONLY "table"
    ADD CONSTRAINT table_pkey PRIMARY KEY (identifier, report_identifier);



ALTER TABLE ONLY "table"
    ADD CONSTRAINT table_report_identifier_chapter_identifier_ordinal_key UNIQUE (report_identifier, chapter_identifier, ordinal);



ALTER TABLE ONLY term_map
    ADD CONSTRAINT term_map_pkey PRIMARY KEY (term_identifier, relationship_identifier, gcid);



ALTER TABLE ONLY term
    ADD CONSTRAINT term_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY term_rel
    ADD CONSTRAINT term_rel_pkey PRIMARY KEY (term_subject, relationship_identifier, term_object);



ALTER TABLE ONLY term
    ADD CONSTRAINT term_unique UNIQUE (lexicon_identifier, context_identifier, context_version, term);



ALTER TABLE ONLY chapter
    ADD CONSTRAINT uk_number_report UNIQUE (number, report_identifier);



ALTER TABLE ONLY webpage
    ADD CONSTRAINT webpage_pkey PRIMARY KEY (identifier);



ALTER TABLE ONLY webpage
    ADD CONSTRAINT webpage_url_key UNIQUE (url);



CREATE INDEX exterm_gcid ON exterm USING btree (gcid);



CREATE INDEX person_names ON person USING btree (name_hash((first_name)::text, (last_name)::text));



CREATE UNIQUE INDEX uk_first_last_orcid ON person USING btree (first_name, last_name, (COALESCE(orcid, 'null'::character varying)));



CREATE UNIQUE INDEX uk_person_names ON person USING btree (name_unique_hash((first_name)::text, (last_name)::text, (orcid)::text));



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON article FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON chapter FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON contributor FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON dataset FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON figure FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON file FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON finding FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON image FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON journal FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON person FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_type FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON report FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON organization FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON organization_type FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON image_figure_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON "table" FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON "array" FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON array_table_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON reference FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_reference_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON webpage FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON book FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_contributor_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON generic FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON organization_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON organization_relationship FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON activity FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON methodology FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON region FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_region_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON publication_file_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON platform FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON instrument FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON instrument_instance FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON instrument_measurement FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON exterm FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON lexicon FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON scenario FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON project FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON model FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON model_run FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON context FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON term FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON relationship FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON term_map FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_row AFTER INSERT OR DELETE OR UPDATE ON term_rel FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON article FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON chapter FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON contributor FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON dataset FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON figure FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON file FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON finding FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON image FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON journal FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON person FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_type FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON report FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON organization FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON organization_type FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON image_figure_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON "table" FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON "array" FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON array_table_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON reference FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_reference_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON webpage FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON book FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_contributor_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON generic FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON organization_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON organization_relationship FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON activity FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON methodology FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON region FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_region_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON publication_file_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON platform FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON instrument FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON instrument_instance FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON instrument_measurement FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON exterm FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON lexicon FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON scenario FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON project FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON model FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON model_run FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON context FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON term FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON relationship FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON term_map FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER audit_trigger_stm AFTER TRUNCATE ON term_rel FOR EACH STATEMENT EXECUTE PROCEDURE audit.if_modified_func('true');



CREATE TRIGGER copy_exterm_inserts_to_term BEFORE INSERT ON exterm FOR EACH ROW EXECUTE PROCEDURE copy_exterm_inserts_to_term();



CREATE TRIGGER delpub BEFORE DELETE ON journal FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON article FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON report FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON chapter FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON figure FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON dataset FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON image FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON finding FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON generic FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON "table" FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON "array" FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON webpage FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON book FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON platform FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER delpub BEFORE DELETE ON instrument FOR EACH ROW EXECUTE PROCEDURE delete_publication();



CREATE TRIGGER update_exterms BEFORE UPDATE ON platform FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_exterms('/platform/');



CREATE TRIGGER update_exterms BEFORE UPDATE ON instrument FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_exterms('/instrument/');



CREATE TRIGGER update_exterms BEFORE UPDATE ON dataset FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_exterms('/dataset/');



CREATE TRIGGER update_exterms BEFORE UPDATE ON organization FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_exterms('/organization/');



CREATE TRIGGER updatepub BEFORE UPDATE ON journal FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON article FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON report FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON chapter FOR EACH ROW WHEN ((((new.identifier)::text <> (old.identifier)::text) OR ((new.report_identifier)::text <> (old.report_identifier)::text))) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON figure FOR EACH ROW WHEN ((((new.identifier)::text <> (old.identifier)::text) OR ((new.report_identifier)::text <> (old.report_identifier)::text))) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON dataset FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON image FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON finding FOR EACH ROW WHEN ((((new.identifier)::text <> (old.identifier)::text) OR ((new.report_identifier)::text <> (old.report_identifier)::text))) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON generic FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON "array" FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON "table" FOR EACH ROW WHEN ((((new.identifier)::text <> (old.identifier)::text) OR ((new.report_identifier)::text <> (old.report_identifier)::text))) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON webpage FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON book FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON platform FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



CREATE TRIGGER updatepub BEFORE UPDATE ON instrument FOR EACH ROW WHEN (((new.identifier)::text <> (old.identifier)::text)) EXECUTE PROCEDURE update_publication();



ALTER TABLE ONLY _report_editor
    ADD CONSTRAINT _report_editor_report_fkey FOREIGN KEY (report) REFERENCES report(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY _report_viewer
    ADD CONSTRAINT _report_viewer_report_fkey FOREIGN KEY (report) REFERENCES report(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY array_table_map
    ADD CONSTRAINT array_table_map_array_identifier_fkey FOREIGN KEY (array_identifier) REFERENCES "array"(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY array_table_map
    ADD CONSTRAINT array_table_map_table_identifier_fkey FOREIGN KEY (table_identifier, report_identifier) REFERENCES "table"(identifier, report_identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY article
    ADD CONSTRAINT article_ibfk_1 FOREIGN KEY (journal_identifier) REFERENCES journal(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY chapter
    ADD CONSTRAINT chapter_ibfk_1 FOREIGN KEY (report_identifier) REFERENCES report(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY context
    ADD CONSTRAINT context_lexicon_identifier_fkey FOREIGN KEY (lexicon_identifier) REFERENCES lexicon(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_ibfk_1 FOREIGN KEY (person_id) REFERENCES person(id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT contributor_organization_fkey FOREIGN KEY (organization_identifier) REFERENCES organization(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY exterm
    ADD CONSTRAINT exterm_lexicon_identifier_fkey FOREIGN KEY (lexicon_identifier) REFERENCES lexicon(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_chapter_report FOREIGN KEY (chapter_identifier, report_identifier) REFERENCES chapter(identifier, report_identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY figure
    ADD CONSTRAINT figure_report_fkey FOREIGN KEY (report_identifier) REFERENCES report(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY finding
    ADD CONSTRAINT finding_chapter_fkey FOREIGN KEY (chapter_identifier, report_identifier) REFERENCES chapter(identifier, report_identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY finding
    ADD CONSTRAINT finding_report_fkey FOREIGN KEY (report_identifier) REFERENCES report(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY organization
    ADD CONSTRAINT fk_org_country FOREIGN KEY (country_code) REFERENCES country(code);



ALTER TABLE ONLY gcmd_keyword
    ADD CONSTRAINT fk_parent FOREIGN KEY (parent_identifier) REFERENCES gcmd_keyword(identifier) DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY contributor
    ADD CONSTRAINT fk_role_type FOREIGN KEY (role_type_identifier) REFERENCES role_type(identifier);



ALTER TABLE ONLY image_figure_map
    ADD CONSTRAINT image_figure_map_figure_fkey FOREIGN KEY (figure_identifier, report_identifier) REFERENCES figure(identifier, report_identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY image_figure_map
    ADD CONSTRAINT image_figure_map_image_fkey FOREIGN KEY (image_identifier) REFERENCES image(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY instrument_instance
    ADD CONSTRAINT instrument_instance_instrument_identifier_fkey FOREIGN KEY (instrument_identifier) REFERENCES instrument(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY instrument_instance
    ADD CONSTRAINT instrument_instance_platform_identifier_fkey FOREIGN KEY (platform_identifier) REFERENCES platform(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY instrument_measurement
    ADD CONSTRAINT instrument_measurement_dataset_identifier_fkey FOREIGN KEY (dataset_identifier) REFERENCES dataset(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY instrument_measurement
    ADD CONSTRAINT instrument_measurement_instrument_identifier_fkey FOREIGN KEY (instrument_identifier) REFERENCES instrument(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY instrument_measurement
    ADD CONSTRAINT instrument_measurement_instrument_identifier_fkey1 FOREIGN KEY (instrument_identifier, platform_identifier) REFERENCES instrument_instance(instrument_identifier, platform_identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY instrument_measurement
    ADD CONSTRAINT instrument_measurement_platform_identifier_fkey FOREIGN KEY (platform_identifier) REFERENCES platform(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY methodology
    ADD CONSTRAINT methodology_activity_identifier_fkey FOREIGN KEY (activity_identifier) REFERENCES activity(identifier);



ALTER TABLE ONLY methodology
    ADD CONSTRAINT methodology_publication_id_fkey FOREIGN KEY (publication_id) REFERENCES publication(id);



ALTER TABLE ONLY model
    ADD CONSTRAINT model_project_identifier_fkey FOREIGN KEY (project_identifier) REFERENCES project(identifier);



ALTER TABLE ONLY model_run
    ADD CONSTRAINT model_run_activity_identifier_fkey FOREIGN KEY (activity_identifier) REFERENCES activity(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY model_run
    ADD CONSTRAINT model_run_model_identifier_fkey FOREIGN KEY (model_identifier) REFERENCES model(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY model_run
    ADD CONSTRAINT model_run_project_identifier_fkey FOREIGN KEY (project_identifier) REFERENCES project(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY model_run
    ADD CONSTRAINT model_run_scenario_identifier_fkey FOREIGN KEY (scenario_identifier) REFERENCES scenario(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY organization_map
    ADD CONSTRAINT organization_map_organization_identifier_fkey FOREIGN KEY (organization_identifier) REFERENCES organization(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY organization_map
    ADD CONSTRAINT organization_map_organization_relationship_identifier_fkey FOREIGN KEY (organization_relationship_identifier) REFERENCES organization_relationship(identifier);



ALTER TABLE ONLY organization_map
    ADD CONSTRAINT organization_map_other_organization_identifier_fkey FOREIGN KEY (other_organization_identifier) REFERENCES organization(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY organization
    ADD CONSTRAINT organization_organization_type_identifier_fkey FOREIGN KEY (organization_type_identifier) REFERENCES organization_type(identifier);



ALTER TABLE ONLY platform
    ADD CONSTRAINT platform_platform_type_identifier_fkey FOREIGN KEY (platform_type_identifier) REFERENCES platform_type(identifier);



ALTER TABLE ONLY publication_contributor_map
    ADD CONSTRAINT publication_contributor_map_contributor_id_fkey FOREIGN KEY (contributor_id) REFERENCES contributor(id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication_contributor_map
    ADD CONSTRAINT publication_contributor_map_publication_id_fkey FOREIGN KEY (publication_id) REFERENCES publication(id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication_contributor_map
    ADD CONSTRAINT publication_contributor_map_reference_publication FOREIGN KEY (reference_identifier, publication_id) REFERENCES reference(identifier, child_publication_id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication_file_map
    ADD CONSTRAINT publication_file_map_file_identifier_fkey FOREIGN KEY (file_identifier) REFERENCES file(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication_file_map
    ADD CONSTRAINT publication_file_map_publication_fkey FOREIGN KEY (publication_id) REFERENCES publication(id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication_gcmd_keyword_map
    ADD CONSTRAINT publication_gcmd_keyword_map_gcmd_keyword_identifier_fkey FOREIGN KEY (gcmd_keyword_identifier) REFERENCES gcmd_keyword(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication_gcmd_keyword_map
    ADD CONSTRAINT publication_gcmd_keyword_map_publication_id_fkey FOREIGN KEY (publication_id) REFERENCES publication(id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication
    ADD CONSTRAINT publication_ibfk_2 FOREIGN KEY (publication_type_identifier) REFERENCES publication_type(identifier) MATCH FULL;



ALTER TABLE ONLY publication_map
    ADD CONSTRAINT publication_map_activity_identifier_fkey FOREIGN KEY (activity_identifier) REFERENCES activity(identifier);



ALTER TABLE ONLY publication_map
    ADD CONSTRAINT publication_map_child_fkey FOREIGN KEY (child) REFERENCES publication(id) ON DELETE CASCADE;



ALTER TABLE ONLY publication_map
    ADD CONSTRAINT publication_map_parent_fkey FOREIGN KEY (parent) REFERENCES publication(id) ON DELETE CASCADE;



ALTER TABLE ONLY publication_region_map
    ADD CONSTRAINT publication_region_map_publication_id_fkey FOREIGN KEY (publication_id) REFERENCES publication(id) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY publication_region_map
    ADD CONSTRAINT publication_region_map_region_identifier_fkey FOREIGN KEY (region_identifier) REFERENCES region(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY reference
    ADD CONSTRAINT reference_child_publication_id_fkey FOREIGN KEY (child_publication_id) REFERENCES publication(id) ON DELETE SET NULL;



ALTER TABLE ONLY report
    ADD CONSTRAINT report_report_type_identifier_fkey FOREIGN KEY (report_type_identifier) REFERENCES report_type(identifier);



ALTER TABLE ONLY publication_reference_map
    ADD CONSTRAINT subpubref_publication_id_fkey FOREIGN KEY (publication_id) REFERENCES publication(id) ON DELETE CASCADE;



ALTER TABLE ONLY publication_reference_map
    ADD CONSTRAINT subpubref_reference_identifier_fkey FOREIGN KEY (reference_identifier) REFERENCES reference(identifier) ON DELETE CASCADE;



ALTER TABLE ONLY "table"
    ADD CONSTRAINT table_chapter_identifier_fkey FOREIGN KEY (chapter_identifier, report_identifier) REFERENCES chapter(identifier, report_identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "table"
    ADD CONSTRAINT table_report_identifier_fkey FOREIGN KEY (report_identifier) REFERENCES report(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY term
    ADD CONSTRAINT term_lexicon_context_version_fkey FOREIGN KEY (lexicon_identifier, context_identifier, context_version) REFERENCES context(lexicon_identifier, identifier, version) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY term_map
    ADD CONSTRAINT term_map_relationship_fkey FOREIGN KEY (relationship_identifier) REFERENCES relationship(identifier) ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY term_map
    ADD CONSTRAINT term_map_term_fkey FOREIGN KEY (term_identifier) REFERENCES term(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY term_rel
    ADD CONSTRAINT term_rel_obj_fkey FOREIGN KEY (term_object) REFERENCES term(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY term_rel
    ADD CONSTRAINT term_rel_relationship_fkey FOREIGN KEY (relationship_identifier) REFERENCES relationship(identifier) ON UPDATE CASCADE ON DELETE RESTRICT;



ALTER TABLE ONLY term_rel
    ADD CONSTRAINT term_rel_subj_fkey FOREIGN KEY (term_subject) REFERENCES term(identifier) ON UPDATE CASCADE ON DELETE CASCADE;



