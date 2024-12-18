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