```docker run --name backend-redis -d redis

build -t backend .
docker run --network="host" backend
```