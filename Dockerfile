FROM php:7.4-fpm

# Arguments defined in docker-compose.yml
ARG user
ARG uid
ENV COMPOSER_ALLOW_SUPERUSER=1

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
    sudo \
    unzip \
    npm \
    nodejs

RUN echo memory_limit = -1 >> /usr/local/etc/php/conf.d/docker-php-memlimit.ini;

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install PHP MongoDB extension 
RUN pecl install mongodb \
    &&  echo "extension=mongodb.so" > $PHP_INI_DIR/conf.d/mongo.ini

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# XDebug configs
COPY my_xdebug.ini "${PHP_INI_DIR}"/conf.d
RUN pecl install xdebug \
   && docker-php-ext-enable xdebug

# Set working directory
WORKDIR /var/www
COPY . .
USER $user

RUN composer install --no-interaction --optimize-autoloader --no-dev

# Optimizing Configuration loading
RUN php artisan config:cache
# Optimizing Route loading
RUN php artisan route:cache
# Optimizing View loading
RUN php artisan view:cache

# para executar algum comando no PHP ao invés do laravel:
# CMD ["php", "/var/www/artisan", "queue:work"]
