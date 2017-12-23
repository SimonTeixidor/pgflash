DROP TABLE IF EXISTS deck CASCADE;

CREATE TABLE deck(
	owner NAME NOT NULL DEFAULT CURRENT_USER references flash_card_user(name),
	name TEXT NOT NULL,
	public BOOLEAN DEFAULT FALSE NOT NULL,
	PRIMARY KEY (owner, name));

ALTER TABLE deck ENABLE ROW LEVEL SECURITY;
CREATE POLICY deck_policy ON deck
USING (owner = current_user OR public)
WITH CHECK (owner = current_user);
