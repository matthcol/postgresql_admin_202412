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

-- generate key with identity (alt. serial)
-- proposed by SQL standard (also mssql, oracle, ...)

-- indexes --