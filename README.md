# my-laravel-container

## Instalação

Primeiro, baixe o instalador do Laravel usando o Composer:

    composer global require laravel/installer

## Criar projeto

    composer create-project --prefer-dist laravel/laravel:^8.0 nome-do-projeto

1. Copiar tudo que foi gerado dentro de "nome-do-projeto" para raiz desse repositório

2. docker-compose up -d

3. Nas versões mais recentes do Laravel o arquivo index.php mudou para server.php, então devemos alterar as referências no arquivo docker-compose/nginx/default.conf


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

# Memory configuration php.ini
RUN echo memory_limit = 128 M >> /opt/docker/etc/php/php.ini

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
### Para executar comandos
Basta copiar o arquivo da seguinte forma:
```
COPY run-api.sh /opt/docker/provision/entrypoint.d/1-run-api.sh
```
Todos os arquivos `/opt/docker/provision/entrypoint.d` são executados automaticamente pelo ponto de entrada padrão.


DOC: https://dockerfile.readthedocs.io/en/latest/content/DockerImages/dockerfiles/php-nginx.html

OBS: O container fica na porta 80
