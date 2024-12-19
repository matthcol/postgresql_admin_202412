## Docker
### Create container
```
docker run --name some-postgres -e POSTGRES_PASSWORD=password -p 5433:5432 -d postgres
```
### start shell  in the container
```
docker exec -it some-postgres bash
```

### logs container
```
docker logs some-postgres
```

### copy host files to container
```
docker cp 02-data-persons.sql some-postgres:/tmp
```

## Docker Composition
```
cd dbmoviedocker
```

### Create containers
```
docker compose up -d
```

### Container lifecycle
```
docker compose start db
docker compose stop db
```

### Copy
```
docker compose cp db:/var/lib/postgresql/data/postgresql.conf .
docker compose cp postgresql.conf db:/var/lib/postgresql/data/
```

### Execute commands
```
docker compose exec -it db bash
docker compose exec -it db psql -U movie -d dbmovie
```

## PgAdmin 4 (GUI)
https://www.pgadmin.org/

## psql (CLI)
### shortcut commands
\? : help
\d : list of relations (table, view, sequence)
\l : list of databases
\q : quit
\i script.sql : execute SQL script
\du : list of users/roles

## Access Control Configuration 
file postgresql.conf defines on which interface/port the rdbms binds
```
listen_addresses = '*' 
# or
listen_addresses = 'localhost' 

port = 5432
```

file pg_hba.conf
(https://www.postgresql.org/docs/current/auth-pg-hba-conf.html)
```
host    dbcity          all              172.30.48.1/32         reject
host    dbcity          @user_city.conf  172.30.0.0/16          scram-sha-256
```

file user_city.conf
```
territory
king
user1
user2
user3
```

see also: pg_ident.conf

test your configuration with psql:
```
psql                                                # defaults: user=OS user, db=user, local connection
psql -U postgres                                    # defaults: db=user, local connection
psql -U postgres -d dbcity                          # local connection
psql -U postgres -d dbcity -h 192.168.1.123         # defaults: port 5432
psql -U territory -d dbcity -h 192.168.1.123 -p 5433
```

## Backup
https://www.postgresql.org/docs/17/backup-dump.html

2 tools: pg_dump (target: 1 database) and pg_dumpall (target: server)

### Full
### pg_dump (Format Plain)
```
pg_dump -U movie -d dbmovie -f backup_dbmovie.dmp
pg_dump -U movie -d dbmovie > backup_dbmovie.dmp
pg_dump -U movie -d dbmovie -Z gzip -f backup_dbmovie.dmp.gz
pg_dump -U movie -d dbmovie -Z gzip:1 -f backup_dbmovie.dmp.1.gz
pg_dump -U movie -d dbmovie -Z gzip:9 -f backup_dbmovie.dmp.9.gz
```

### pg_dump (Format Custom)
```
pg_dump -U movie -d dbmovie -F c -f backup_dbmovie.custom
```

### pg_dump (Format Directory and Tar)
```
pg_dump -U movie -d dbmovie -F d -f backup_dbmovie_dir
```

### pg_dumpall
Whole server or list of users

```
pg_dumpall -U movie -r -f backup_users.dump
```

## partial dump
- model only: -s
- data only: -a
- filters: schema, tables, ...: -n, -t, -T

## Restore
### database (format plain sql)
```
psql -U postgres -d dbmoviewin -f backup_dbmovie.dmp
psql -U postgres -d dbmoviewin < backup_dbmovie.dmp
```
### users (format plain sql)
NB: use maintenane database
```
psql -U postgres -d postgres -f backup_users.dump
```

### full or partial restore
With custom, directory or tar dump only:
-n : schema
-t : table
```
pg_restore -U movie -d dbmovie -t play backup_dbmovie.custom
```



