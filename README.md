# my-laravel-container

## Instalação

Primeiro, baixe o instalador do Laravel usando o Composer:

    composer global require laravel/installer

## Criar projeto

    composer create-project --prefer-dist laravel/laravel:^8.0 nome-do-projeto

1. Copiar tudo que foi gerado dentro de "nome-do-projeto" para raiz desse repositório

2. docker-compose up -d


## PHP + NGINX no mesmo Dockerfile
```
FROM webdevops/php-nginx:7.4-alpine

# Install Laravel framework system requirements (https://laravel.com/docs/8.x/deployment#optimizing-configuration-loading)
RUN apk add oniguruma-dev postgresql-dev libxml2-dev
RUN docker-php-ext-install \
        bcmath \
        ctype \
        fileinfo \
        json \
        mbstring \
        pdo_mysql \
        pdo_pgsql \
        tokenizer \
        xml

# Copy Composer binary from the Composer official Docker image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

ENV WEB_DOCUMENT_ROOT /app/public
ENV APP_ENV production
WORKDIR /app
COPY . .

RUN composer install --no-interaction --optimize-autoloader --no-dev
# Optimizing Configuration loading
RUN php artisan config:cache
# Optimizing Route loading
RUN php artisan route:cache
# Optimizing View loading
RUN php artisan view:cache

# RUN Migrates
RUN yes | php artisan migrate

RUN chown -R application:application .
```
OBS: O container fica na porta 80
