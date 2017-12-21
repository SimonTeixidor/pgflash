-- Cleanup
drop schema api cascade;
drop table card cascade;
drop table deck cascade;
drop role web_anon;
drop function next_card(int);

-- Create schemas
create schema api;

-- Tables
create table deck(
	id serial primary key,
	name text,
	private boolean);
create table card(
       	front text, 
	back text,
	bucket int,
	deck int references deck(id));

-- Public Views
create view api.public_decks as 
select id, name from deck where not private;

-- Public Role
create role web_anon nologin;
grant web_anon to postgres;

grant usage on schema api to web_anon;
grant select on api.public_decks to web_anon;

-- Core logic

-- The bucket from which the next card should be pulled is the first bucket
-- with more cards in it than the square of the bucket number. That is, we
-- pull a card from bucket 3 once it has more than 9 cards in it.
create view next_bucket as
select deck, max(bucket) as bucket from (
	select deck,bucket from card
	group by (deck,bucket) having count(*) > power(bucket, 2)
) as sub group by deck;

create view next_card as
-- The next card is either the first card in the overflowing
-- largest overflowing bucket, or a random card.
select distinct on (c.deck) c.* from (
	select c.* from card c inner join next_bucket nb on nb.deck = c.deck and nb.bucket = c.bucket
	union all
	(select * from card order by random())
) as c;
