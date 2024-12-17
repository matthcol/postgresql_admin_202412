
-- First connection

-- current connected database 
select current_database();

-- current connected user
select current_user;
select "current_user"();

-- list of databases
select * from pg_database;

-- list of tables
select * from pg_tables where schemaname = 'public';


-- view (logical view):
create view movie_current_year as
select * from movie
where year = extract(year from current_date);

-- delete view:
drop view movie_current_year;

-- recreate view here

select * from movie_current_year;

-- realign sequence (after import data)
select setval('movie_id_seq', max(id)) from movie;

insert into movie (title, year) values ('Venom: The Last Dance', 2024);
insert into movie (title, year) values ('Dune: Part Two', 2024);
insert into movie (title, year) values ('L''Amour Fou', 2024); -- 8079251

select * from movie where year = 2024;
select * from movie_current_year;

update movie set title = 'L''Amour Ouf' where id = 8079251;
select * from movie_current_year;

-- materialized view = view with copy (syncro: one shot, manual, auto delay)


-- table
-- columns: name/type + null/not null + constraint
-- rows (data)

-- constraints:
-- * primary key (PK)


-- generate automatically PK (server side)
-- * solution 1: smallserial/serial/bigserial resp. smallint, int/integer, bigint
--		=> clause default + sequence created auto
-- * solution 2:  clause identity (create auto sequence)















