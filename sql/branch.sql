BEGIN;
    ALTER TABLE tips ADD COLUMN paid_in_advance currency_amount;

    DROP VIEW current_tips;
    CREATE VIEW current_tips AS
        SELECT DISTINCT ON (tipper, tippee) *
          FROM tips
      ORDER BY tipper, tippee, mtime DESC;

    DROP TRIGGER IF EXISTS update_current_tip ON current_tips;
    CREATE OR REPLACE FUNCTION update_tip() RETURNS trigger AS $$
        BEGIN
            UPDATE tips
               SET is_funded = NEW.is_funded
                 , paid_in_advance = NEW.paid_in_advance
             WHERE id = NEW.id;
            RETURN NULL;
        END;
    $$ LANGUAGE plpgsql;
    CREATE TRIGGER update_current_tip INSTEAD OF UPDATE ON current_tips
        FOR EACH ROW EXECUTE PROCEDURE update_tip();
END;
