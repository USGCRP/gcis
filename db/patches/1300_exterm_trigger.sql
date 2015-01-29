CREATE OR REPLACE FUNCTION update_exterms() RETURNS TRIGGER AS $$
BEGIN
    /* params are old, new */
    update exterm set gcid = TG_ARGV[0] || NEW.identifier where gcid = TG_ARGV[0] ||  OLD.identifier;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

create trigger update_exterms before update on platform for each row when (NEW.identifier != OLD.identifier) execute procedure update_exterms('/platform/');
create trigger update_exterms before update on instrument for each row when (NEW.identifier != OLD.identifier) execute procedure update_exterms('/instrument/');
create trigger update_exterms before update on dataset for each row when (NEW.identifier != OLD.identifier) execute procedure update_exterms('/dataset/');

