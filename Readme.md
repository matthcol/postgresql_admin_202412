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

## PgAdmin 4 (GUI)
https://www.pgadmin.org/