-- DAY 2 --
-- start in db dbmovie --
SELECT * FROM pg_collation;
SELECT * FROM pg_collation where collname like 'fr-FR%';

CREATE DATABASE dbcity
    WITH
    OWNER = postgres
    -- TEMPLATE = template1 -- default
	TEMPLATE = template0 -- to enable collation provider ICU
    ENCODING = 'UTF8'
    ICU_LOCALE = 'fr-FR'
    LOCALE_PROVIDER = 'icu'
;

-- go to db dbcity --
DROP TABLE city;

CREATE TABLE city
(
	-- columns
    id integer,
    name character varying(50) NOT NULL,
    zipcode char(5),
	-- table constraints
    CONSTRAINT pk_city PRIMARY KEY (id)
);

insert into city values (1, 'Toulouse', '31000');
insert into city values (1, 'Toulouse', '31100');
-- ERROR:  Key (id)=(1) already exists.duplicate key value violates unique constraint "pk_city" 

-- generate key with identity (alt. serial)
-- proposed by SQL standard (also mssql, oracle, ...)

-- recreate table with id generated with clause identity (mode always)
DROP TABLE city;
CREATE TABLE city
(
	-- columns
    id integer GENERATED ALWAYS AS IDENTITY, -- create sequence city_id_seq
    name character varying(50) NOT NULL,
    zipcode char(5),
	-- table constraints
    CONSTRAINT pk_city PRIMARY KEY (id)
);

insert into city (name, zipcode) values ('Toulouse', '31000');
insert into city (name, zipcode) values ('Toulouse', '31100');
select * from city;

insert into city (id, name, zipcode) values (3, 'Toulouse', '31200');
-- ERROR:  Column "id" is an identity column defined as GENERATED ALWAYS.cannot insert a non-DEFAULT value into column "id" 

insert into city (id, name, zipcode) values (DEFAULT, 'Toulouse', '31200');

-- recreate table with id generated with clause identity (mode default)
DROP TABLE city; -- drop also sequence city_id_seq
CREATE TABLE city
(
	-- columns
    id integer GENERATED BY DEFAULT AS IDENTITY, -- create sequence city_id_seq
    name character varying(50) NOT NULL,
    zipcode char(5),
	-- table constraints
    CONSTRAINT pk_city PRIMARY KEY (id)
);
insert into city (name, zipcode) values ('Toulouse', '31000');
insert into city (name, zipcode) values ('Toulouse', '31100');
select * from city;
-- force id
insert into city (id, name, zipcode) values (3, 'Toulouse', '31200');
select * from city;
insert into city (id, name, zipcode) values (DEFAULT, 'Toulouse', '31300'); -- call nextval('city_id_seq') => 3


-- sequence operations
select currval('city_id_seq'); -- 3 (NB! only available, if generated in this session)
select nextval('city_id_seq'); -- execute n times: 4, 5, 6, 7, ..., 18

-- in an // session: 2 x nextval/currval

select currval('city_id_seq'); -- keep 18
select nextval('city_id_seq'); -- 21
select currval('city_id_seq'); -- 21

select setval('city_id_seq', 100);
select nextval('city_id_seq'); -- 101
-- in the // session: nextval => 102

-- in restricted mode
select setval('city_id_seq', max(id)) from city;
-- open all connections again
insert into city (name, zipcode) values ('Belfort', '90000');
insert into city (name, zipcode) values ('Bonneuil-sur-Marne', '94380');
select * from city; -- new ids: 4,5

-- wrong data
insert into city (id, name, zipcode) values (3000, 'Toulouse', '31200');
delete from city where id = 3000;


-- RECAP langage SQL
-- * DDL: Data Definition Language => objects of a database (database, schema, table, view, constraint, sequence, index, ...)
--     - CREATE
--     - ALTER
--     - DROP
-- * DML: Data Manipulation Language (CRUD)
--     - INSERT : add data
--     - DELETE : delete data (row(s) not the table !)
--     - UPDATE : modify data
--     - SELECT : read data
-- * Transactions: COMMIT, ROLLBACK, BEGIN
-- * Privileges: GRANT, REVOKE

-- villes avec accents: Montbéliard, Montbard, Montcuq, Montbuisson, L'Haÿ-les-Roses, Besançon, Phœnix 
INSERT INTO city (name) VALUES
	('Montbéliard'),
	('Montbard'),
	('Montcuq'),
	('Montbuisson'),
	('L''Haÿ-les-Roses'),
	('Besançon'),
	('Phœnix');

INSERT INTO city (name, zipcode) VALUES ('Pau', 64000) RETURNING id;

select * from city order by name;
-- OK according to collation fr_FR
-- NB: collation can be set in: database, table, column, query

select * from city order by name collate "es-ES-x-icu";
SELECT * FROM pg_collation where collname like 'es%';

INSERT INTO city (name) VALUES
	('Mañana'),
	('Mano'),
	('Matador');
select * from city order by name; -- FR: Mañana, Mano, Matador
select * from city order by name collate "es-ES-x-icu"; -- Mano, Mañana, Matador


select * from city order by id desc;

-- ********************************** --
-- Schema, user, role, privileges     --
-- ********************************** --
-- https://www.postgresql.org/docs/17/sql-grant.html


-- schema
select * from city;
select * from public.city;

CREATE SCHEMA territory;
DROP TABLE public.city;
CREATE TABLE territory.city
(
	-- columns
    id integer GENERATED BY DEFAULT AS IDENTITY, -- create sequence city_id_seq
    name character varying(50) NOT NULL,
    zipcode char(5),
	-- table constraints
    CONSTRAINT pk_city PRIMARY KEY (id)
);
select * from city; -- relation "city" does not exist
select * from territory.city;

show search_path; -- session variable defined from connected user settings

-- change search_path for this session
set search_path = "territory","public";
set search_path = territory,public;
set search_path = territory;
show search_path;
select * from city;


create user territory with 
	login
	password 'password';
GRANT USAGE ON SCHEMA territory TO territory;
GRANT SELECT ON territory.city TO territory;

-- session user territory
show search_path; --  "$user", public  => $user = territory here
select * from city; -- ok
select * from territory.city; -- ok
delete from city; -- ko: ERROR:  permission denied for table city
-- end session


-- other strategy for user territory
revoke SELECT ON territory.city FROM territory;
REVOKE USAGE ON SCHEMA territory FROM territory;
ALTER SCHEMA territory OWNER TO territory; 
-- NB: during creation: CREATE SCHEMA territory AUTHORIZATION territory;
DROP TABLE territory.city;

-- session user territory
select current_user, current_database(); -- "territory"	"dbcity"
show search_path; -- """$user"", public"
CREATE TABLE city -- in schema territory
(
	-- columns
    id integer GENERATED BY DEFAULT AS IDENTITY, -- create sequence city_id_seq
    name character varying(50) NOT NULL,
    zipcode char(5),
	-- table constraints
    CONSTRAINT pk_city PRIMARY KEY (id)
);
select * from city;
INSERT INTO city (name) VALUES
	('Montbéliard'),
	('Montbard'),
	('Montcuq'),
	('Montbuisson'),
	('L''Haÿ-les-Roses'),
	('Besançon'),
	('Phœnix');
select * from city;
update city set zipcode = '25200' where id = 1; -- Montbéliard (id=1)
select * from city;
delete from city where id = 7; -- "Phœnix" (id=7)
select * from city;

-- back to session DBA postgres
create user king with
	login
	password 'password';
grant usage on schema territory to king;
grant select, insert, update(zipcode) on territory.city to king;
ALTER USER king IN DATABASE dbcity
    SET search_path TO territory;

-- session user king
show search_path; -- "territory"
select * from city;
insert into city (name) values ('Toulouse'); -- id = 8
select * from city; -- OK
update city set zipcode = '31000' where id = 8; -- OK
update city set name = 'TOULOUSE' where id = 8; -- KO: ERROR:  permission denied for table city 
delete from city; -- KO: ERROR:  permission denied for table city 

-- session DBA postgres
-- NB: with PostgreSQL keywords USER and ROLE are equivalent
create role city_reader;
grant usage on schema territory to city_reader;
grant select on territory.city to city_reader;

create role city_manager_l1;
grant city_reader to city_manager_l1;
grant insert, update(zipcode) on territory.city to city_manager_l1;

create user user1 
with 
	login 
	password 'password';
create user user2 
with 
	login 
	password 'password';
create user user3
with 
	login 
	password 'password';

grant city_reader to user1;
grant city_reader to user2;
grant city_manager_l1 to user3;

-- session user1
set role city_reader;
select * from territory.city;
reset role;

-- session user2 with role city_reader
select * from territory.city;

-- session user3 with role city_manager_l1
select * from territory.city;
insert into territory.city (name) values ('Pau');
delete from territory.city; -- ko: ERROR:  permission denied for table city
select current_user, session_user; -- "city_manager_l1", "user3"


-- session DBA postgres on dbmovie
create user user4
with 
	login 
	password 'password';
-- default: grant usage on schema public to user4;
grant select on all tables in schema public to user4; -- all tables are in the schema public in this database 
-- NB: does not work for future tables !

-- session user4 on dbmovie
select * from movie;
select * from person;

-- default role PUBLIC (everybody has this role)
-- old versions of postgresql, improve security (default: ALL)
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
-- new versions of postgresql have only USAGE privilege by default
-- all versions of postgresql, deactivate usage of schema public
REVOKE ALL ON SCHEMA public FROM PUBLIC;
-- NB: never drop schema public (used by some extensions or plugins)

-- access control --
-- config files: 
-- * postgresql.conf : general config file (network interface, logs, wals, ... )
-- * pg_hba.conf : access control (user, db, client, mode auth)

-- (TODO)
-- indexes  --
-- vacuumm / analyze + filesystem --
-- statistics --
-- backup/restore + wals/pitr