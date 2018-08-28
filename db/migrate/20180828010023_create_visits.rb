Sequel.migration do
  up do

    create_table :visits do
      primary_key :id
      String :url, null: false, text: true
      String :referer, text: true
      Time :created_at, null: false
      String :hash, null: false, size: 32
    end

    # Create an index for aggregating data by day
    run "CREATE INDEX visits_date_url ON visits ((date_trunc('day'::text, created_at)::date), url)"

    # Use a PL/PgSQL function in a before isnert trigger to set the hash.
    # The spec indicates that the hash should include the id, and instead of executing multiple
    # roundtrips to get the nextval() or assuming only one client is inserting in the loop,
    # a trigger is used to have the database create the hash on insert
    run <<~SQL
      CREATE OR REPLACE FUNCTION set_hash() RETURNS trigger LANGUAGE plpgsql AS $$
        BEGIN
          NEW.hash := MD5(NEW.id::VARCHAR || NEW.url || COALESCE(NEW.referer, '') || NEW.created_at::VARCHAR);
          RETURN NEW;
        END;
        $$ STRICT IMMUTABLE
    SQL

    # Set a before insert trigger to set the hash before insert
    run <<~SQL
      CREATE TRIGGER trg_set_hash BEFORE INSERT ON visits FOR EACH ROW EXECUTE PROCEDURE set_hash()
    SQL
  end

  down do
    drop_table :visits
    drop_function :set_hash
  end

end
