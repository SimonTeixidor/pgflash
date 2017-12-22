DROP TABLE IF EXISTS card CASCADE;
DROP FUNCTION increment_bucket_count();
DROP FUNCTION decrement_bucket_count();

CREATE TABLE card(
       	front TEXT NOT NULL, 
	back TEXT NOT NULL,
	bucket INT NOT NULL,
	deck_owner NAME NOT NULL,
	deck_name TEXT NOT NULL,
	PRIMARY KEY (front, back, deck_owner, deck_name),
	FOREIGN KEY (deck_owner, deck_name) REFERENCES deck(owner, name));

CREATE INDEX card_deck ON card(deck_owner, deck_name);

CREATE FUNCTION increment_bucket_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
  BEGIN
    -- Increment the count if the bucket already exists
    UPDATE bucket_count SET count = count + 1 
    WHERE bucket = new.bucket and deck_owner = new.deck_owner and deck_name = new.deck_name;

    -- Otherwise create a new entry
    INSERT INTO bucket_count (bucket, deck_owner, deck_name, count) 
    (
      SELECT new.bucket,new.deck_owner,new.deck_name,1
      WHERE NOT EXISTS(
        SELECT 1 FROM bucket_count bc 
        WHERE bc.bucket=new.bucket AND bc.deck_owner=new.deck_owner AND bc.deck_name=new.deck_name
      )
    );
    RETURN NEW;
  END;
$$;

CREATE FUNCTION decrement_bucket_count()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
  BEGIN
    UPDATE bucket_count SET count = count - 1
    WHERE bucket = old.bucket and deck_owner = old.deck_owner and deck_name = old.deck_name;
    DELETE FROM bucket_count WHERE count = 0;
    RETURN NEW;
  END;
$$;

CREATE TRIGGER bucket_count_update_new
BEFORE INSERT OR UPDATE on card
FOR EACH ROW
EXECUTE PROCEDURE increment_bucket_count();

CREATE TRIGGER bucket_count_update_old
BEFORE UPDATE on card
FOR EACH ROW
EXECUTE PROCEDURE decrement_bucket_count();
