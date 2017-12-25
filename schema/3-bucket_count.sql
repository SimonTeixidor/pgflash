DROP TABLE IF EXISTS bucket_count CASCADE;

CREATE TABLE bucket_count(
	deck_owner NAME NOT NULL,
	deck_name TEXT NOT NULL,
	bucket INT NOT NULL,
	count INT NOT NULL,
	PRIMARY KEY (deck_owner, deck_name, bucket),
	FOREIGN KEY (deck_owner, deck_name) references pub.deck(owner, name));

ALTER TABLE bucket_count ENABLE ROW LEVEL SECURITY;
CREATE POLICY bucket_policy ON bucket_count
USING (deck_owner = current_user)
WITH CHECK (deck_owner = current_user);
