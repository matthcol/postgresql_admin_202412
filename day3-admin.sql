-- ************************************************** --
-- 	INDEXES and STATISTICS		 					   --
-- ************************************************** --
select * from movie where year = 1984;

select * from movie where id = 87363; -- Gremlins (1984)
-- uses index pk_movie (primary key)

select * from movie where duration > 300;
-- no index (examines whole table)


-- * index Binary Tree = BTREE
-- 		cost = log(n), n = nb of rows
-- Example:
--   n = 1000      cost = 10
--   n = 1M        cost = 20
--   n = 1G        cost = 30
--   n = 1T        cost = 40
--   n = 1P
--   n = 1E        cost = 60

-- * implicit index: constraints PRIMARY KEY, UNIQUE
select * from pg_indexes where schemaname = 'public';

-- drop index uniq_movie associated to constraint uniq_movie
alter table movie drop constraint uniq_movie;
select * from pg_indexes where schemaname = 'public';

create index idx_person_name on person(name); -- default: BTREE, non unique
create index idx_movie_title on movie(title);
select * from pg_indexes where schemaname = 'public';

select * from person where name = 'Clint Eastwood'; -- 1 result
select * from person where name = 'Steve McQueen'; -- 1 entry => 2 rows

select * from movie where title = 'The Man Who Knew Too Much';

select * from person where name = 'clint eastwood'; -- no result (CS)
select * from person where lower(name) = 'clint eastwood'; -- 1 result, NO INDEX

-- to use like operator: cf doc (depends on your locale)
select * from person where name like 'Clint %';
select * from person where name like 'Clint East%';

-- improve text index:
-- * sol1: Case Insensitive using an index on the result of a function
drop index idx_person_name;
create index idx_person_name on person(lower(name));
select * from pg_indexes where schemaname = 'public';
select * from person where lower(name) = 'clint eastwood'; -- OK: index
select * from person where lower(name) like 'clint eastwoo%';

-- statistics help PostgreSQL planner to decide wether to use or not an index
-- https://www.postgresql.org/docs/17/planner-stats.html

analyze person;
-- idea of the anlyzer query: 
select 
	count(distinct lower(name))::decimal / count(*)::decimal as ratio_name,
	count(distinct lower(name)) as nb_distinct_name, 
	count(*) as nb_rows
from person;

-- statistics of a table (ndistinct)
SELECT attname, inherited, n_distinct,
       array_to_string(most_common_vals, E'\n') as most_common_vals
FROM pg_stats
WHERE tablename = 'person';

SELECT attname, inherited, n_distinct,
       array_to_string(most_common_vals, E'\n') as most_common_vals
FROM pg_stats
WHERE tablename = 'movie';


-- different type of indexes
-- https://www.postgresql.org/docs/17/indexes.html
-- BTREE, HASH, BRIN, GiST, SP-GiST

-- see also Fulltext Search: 
-- doc: https://www.postgresql.org/docs/17/textsearch.html
-- article: https://neon.tech/postgresql/postgresql-indexes/postgresql-full-text-search
-- predicate used: tsvector @@ tsquery

-- how it works
SELECT to_tsvector('english', 'star wars: return of the Jedi'); -- 'jedi':6 'return':3 'star':1 'war':2
SELECT to_tsvector('english', 'star wars: return of the Jedi')
	@@ to_tsquery('jedi | star | love'); -- true
SELECT to_tsvector('english', 'star wars: return of the Jedi')
	@@ to_tsquery('jedi & star & love'); -- false

-- index creation
create index idx_movie_title_fts
on movie
using GIN((to_tsvector('english', title)));

-- example using index
select * from movie 
where to_tsvector('english', title) @@ to_tsquery('star & war');


-- Tracking queries and other statistics
-- https://www.postgresql.org/docs/17/monitoring-stats.html
select * from pg_stat_user_tables;
select * from pg_stat_user_indexes;
select * from pg_stat_user_tables where relname = 'person';
-- enable module in postgresql.conf: shared_preload_libraries = 'pg_stat_statements'
create extension pg_stat_statements;
select * from pg_stat_statements;

-- ************************************************** --
-- 			FILE SYSTEM 		 					   --
-- ************************************************** --
-- NB: 1 file, 1 data = 1G max
--
-- directories
--		* data/global: catalog of transverval objects (bases, users, tablespaces)
-- 		* data/base: tables, indexes, toasts, ... of each database
--
-- Each database has its own directory
select * from pg_database;
-- dbmovie: oid=16384 => directory: data/base/16384

-- Each table (or index, toast, ...) has its own file
select * from pg_tables;
select * from pg_class;
select * from pg_class where relname = 'movie';
-- oid = 16393
-- relfilenode = 16393 => filename ~ 920K
-- 1 to 3 files: 16393 (, 16393_fsm, 16393_vm)	

-- FSM: Free Space Map: tree of FSM pages
-- VM: Visibility Map: row visibility according to transactions

vacuum movie; 
select year, title from movie where year % 2 = 1;
delete from movie where year % 2 = 1; -- KO: a FK constraint references this table
delete from play where movie_id in (
	select id from movie where year % 2 = 1
); -- DELETE 33540
delete from have_genre where movie_id in (
	select id from movie where year % 2 = 1
); -- DELETE 1711
delete from movie where year % 2 = 1;
select count(*) from movie; -- 595

-- FSM file is not modified after 'delete' operations
vacuum movie; 
-- FSM file has changed (new cartography of free spaces)

vacuum full movie; -- lock on table movie during operation
-- copy data on new file
-- oid is kept
-- relfilenode is change: 16461 = filename ~ 480K (no FSM and VM at this point)
select * from pg_class where relname = 'movie';

-- new data
insert into movie (title, year) values ('Venom: The Last Dance', 2024);
insert into movie (title, year) values ('Dune: Part Two', 2024);
insert into movie (title, year) values ('L''Amour Ouf', 2024); 
insert into movie (title, year) values ('L''Amour Fou', 2024); 
select * from movie where year = 2024;
delete from movie where id in (8079252, 8079249);
vacuum movie; -- FSM and VM files are created

-- combine both vacuum and analyze
vacuum analyze movie;

-- vacuum base
vacuum;
vacuum full;
vacuum full analyze;

select * from pg_stat_user_tables where relname = 'movie';

-- autovacuum possible: cf postgresql.conf

-- reindex: https://www.postgresql.org/docs/17/sql-reindex.html
reindex index idx_movie_title;
-- if not working: drop + create index

-- tablespaces: usefull when using physical disk
select * from pg_class where relname = 'movie'; -- reltablespace: 0 = default
select * from pg_tablespace; -- pg_default: oid = 1663
select pg_tablespace_location(1663); -- blank

create tablespace my_tablespace location '/opt/pg_extra_ts';
select * from pg_tablespace; -- new ts oid = 17344
select pg_tablespace_location(17344);
drop tablespace my_tablespace;

select * from pg_tables order by tablename;

-- backup/restore
-- add 2 users fan, manager (default: usage on public)
grant select on all tables in schema public to fan;
grant select, insert on all tables in schema public to manager;






