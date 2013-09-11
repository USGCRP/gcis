CREATE OR REPLACE FUNCTION update_publication() RETURNS TRIGGER AS $$
BEGIN
    update publication set fk = slice(hstore(NEW.*),akeys(fk))
         where publication_type_identifier = TG_TABLE_NAME::text and
            fk = slice(hstore(OLD.*),akeys(fk));
     RETURN NEW;
END; $$ LANGUAGE plpgsql;


