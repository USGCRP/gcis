
CREATE OR REPLACE FUNCTION delete_publication() RETURNS TRIGGER AS $$
BEGIN
    delete from publication
         where publication_type = TG_TABLE_NAME::text and
            fk = slice(hstore(OLD.*),akeys(fk));
    RETURN OLD;
END; $$ LANGUAGE plpgsql;

create trigger delpub before delete on journal for each row execute procedure delete_publication();
create trigger delpub before delete on article for each row execute procedure delete_publication();
create trigger delpub before delete on report  for each row execute procedure delete_publication();
create trigger delpub before delete on chapter for each row execute procedure delete_publication();
create trigger delpub before delete on figure  for each row execute procedure delete_publication();
create trigger delpub before delete on dataset for each row execute procedure delete_publication();
create trigger delpub before delete on image   for each row execute procedure delete_publication();
create trigger delpub before delete on finding for each row execute procedure delete_publication();

/************/

CREATE OR REPLACE FUNCTION update_publication() RETURNS TRIGGER AS $$
BEGIN
    update publication set fk = slice(hstore(NEW.*),akeys(fk))
         where publication_type = TG_TABLE_NAME::text and
            fk = slice(hstore(OLD.*),akeys(fk));
     RETURN NEW;
END; $$ LANGUAGE plpgsql;

create trigger updatepub before update on journal for each row when ( NEW.identifier != OLD.identifier ) execute procedure update_publication();
create trigger updatepub before update on article for each row when ( NEW.identifier != OLD.identifier ) execute procedure update_publication();
create trigger updatepub before update on report  for each row when ( NEW.identifier != OLD.identifier ) execute procedure update_publication();
create trigger updatepub before update on chapter for each row when ( NEW.identifier != OLD.identifier or NEW.report != OLD.report ) execute procedure update_publication();
create trigger updatepub before update on figure  for each row when ( NEW.identifier != OLD.identifier or NEW.report != OLD.report ) execute procedure update_publication();
create trigger updatepub before update on dataset for each row when ( NEW.identifier != OLD.identifier ) execute procedure update_publication();
create trigger updatepub before update on image   for each row when ( NEW.identifier != OLD.identifier ) execute procedure update_publication();
create trigger updatepub before update on finding for each row when ( NEW.identifier != OLD.identifier or NEW.report != OLD.report ) execute procedure update_publication();

