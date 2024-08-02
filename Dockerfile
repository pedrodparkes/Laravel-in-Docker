ARG NODE_VERSION=18.19.1
FROM node:${NODE_VERSION}-bullseye AS node

FROM php:8.2-fpm-bullseye as fpm-server

COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

RUN apt update && apt install -y zip unzip git cron procps libcurl4-openssl-dev zlib1g-dev libpng-dev  libgmp-dev libxml2-dev
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install bcmath gd gmp dom curl mysqli pdo pdo_mysql && docker-php-ext-enable pdo_mysql
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY --chown=www-data:www-data . /var/www/html

RUN rm *.lock | true
RUN mv .env.example .env
RUN mkdir -p /var/www/html/storage/framework/sessions && mkdir -p /var/www/html/storage/framework/views && mkdir -p /var/www/html/storage/framework/cache && mkdir -p /var/www/html/storage/logs
RUN pwd
RUN composer install
RUN mkdir /logs
RUN chown www-data:www-data /var/www/html/ -R

WORKDIR /var/www/html
RUN npm install
RUN npm run build
USER  www-data


FROM nginx:1.20-alpine as web-server
WORKDIR /var/www/html
COPY docker/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=fpm-server --chown=www-data /var/www/html /var/www/html
RUN mkdir /logs


# We need a CRON container to the Laravel Scheduler.
# We'll start with the CLI container as our base,
# as we only need to override the CMD which the container starts with to point at cron
FROM fpm-server as fpm-cron
WORKDIR /var/www/html
COPY --from=fpm-server --chown=www-data /var/www/html /var/www/html
USER root
RUN touch laravel.cron && \
    echo "* * * * * cd /var/www/html && /usr/local/bin/php artisan schedule:run >> /var/log/cron.log 2>&1" >> laravel.cron && \
    crontab laravel.cron
RUN touch /var/log/cron.log | true
CMD ["cron", "-f"]
