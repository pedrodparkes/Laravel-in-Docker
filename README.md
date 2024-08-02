## HowTo Use

#### 1. Put files from this repo to your Laravel project dir
#### 2. Do a test docker build
```shell
SHORT_COMMIT=`git rev-parse --short HEAD`

# Build-fpm-server
DOCKER_BUILDKIT=0 docker buildx build -f Dockerfile --target fpm-server -t fpm-server:${SHORT_COMMIT} . --no-cache=true

# Build-web-server
DOCKER_BUILDKIT=0 docker buildx build -f Dockerfile --target web-server -t web-server:${SHORT_COMMIT} . --no-cache=true

# Build-fpm-cron
DOCKER_BUILDKIT=0 docker buildx build -f Dockerfile --target fpm-cron -t fpm-cron:${SHORT_COMMIT} . --no-cache=true
```

#### Run app locally with docker-compose
```shell
docker-compose up
```
