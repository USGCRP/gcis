
CREATE OR REPLACE FUNCTION delete_publication() RETURNS TRIGGER AS $$
BEGIN
    delete from publication
         where publication_type_identifier = TG_TABLE_NAME::text and
            fk = slice(hstore(OLD.*),akeys(fk));
    RETURN OLD;
END; $$ LANGUAGE plpgsql;

