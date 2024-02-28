FROM php:7.4-fpm

# Arguments defined in docker-compose.yml
ARG user
ARG uid
ENV COMPOSER_ALLOW_SUPERUSER=1

# Set working directory
WORKDIR /var/www
COPY . .

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libgd-dev \
    jpegoptim optipng pngquant gifsicle \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    zlib1g-dev \
    libzip-dev \
    sudo \
    npm \
    nodejs

RUN echo memory_limit = -1 >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini;

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip

# Install PHP MongoDB extension 
RUN pecl install mongodb \
    &&  echo "extension=mongodb.so" > $PHP_INI_DIR/conf.d/mongo.ini

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# XDebug configs
COPY my_xdebug.ini "${PHP_INI_DIR}"/conf.d
RUN pecl install xdebug \
   && docker-php-ext-enable xdebug

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Configurar a quantidade de memória no PHP
RUN echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-memory-limit.ini
# Ajustar as configurações do PHP-FPM
RUN echo "php_admin_value[memory_limit] = 512M" >> /usr/local/etc/php-fpm.d/www.conf

# Adjust PHP-FPM settings
RUN sed -i 's/pm.start_servers = [0-9]*/pm.start_servers = 8/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/pm.max_children = [0-9]*/pm.max_children = 20/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/pm.min_spare_servers = [0-9]*/pm.min_spare_servers = 4/' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i 's/pm.max_spare_servers = [0-9]*/pm.max_spare_servers = 12/' /usr/local/etc/php-fpm.d/www.conf

RUN composer install --no-interaction --optimize-autoloader --no-dev

# Optimizing Configuration loading
RUN php artisan config:cache
# Optimizing Route loading
RUN php artisan route:cache
# Optimizing View loading
RUN php artisan view:cache

USER $user
# para executar algum comando no PHP ao invés do laravel:
# CMD ["php", "/var/www/artisan", "queue:work"]
