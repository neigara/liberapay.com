BEGIN;
    ALTER TABLE tips ADD COLUMN paid_in_advance currency_amount;
    ALTER TABLE tips ADD CONSTRAINT paid_in_advance_currency_chk CHECK (paid_in_advance::currency = amount::currency);

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

ALTER TYPE transfer_context ADD VALUE IF NOT EXISTS 'tip-in-advance';
BEGIN;
    ALTER TABLE transfers ADD COLUMN unit_amount currency_amount;
    ALTER TABLE transfers ADD CONSTRAINT unit_amount_currency_chk CHECK (unit_amount::currency = amount::currency);
END;
