DROP TABLE IF EXISTS bucket_count CASCADE;

CREATE TABLE bucket_count(
	deck_owner NAME NOT NULL,
	deck_name TEXT NOT NULL,
	bucket INT NOT NULL,
	count INT NOT NULL,
	PRIMARY KEY (deck_owner, deck_name, bucket));
