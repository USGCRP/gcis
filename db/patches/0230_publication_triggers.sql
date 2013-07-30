CREATE OR REPLACE FUNCTION delete_publication() RETURNS TRIGGER AS $$
BEGIN
    delete from publication where length( (fk - hstore(OLD.*))::text ) = 0;
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

