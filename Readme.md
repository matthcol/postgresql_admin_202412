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