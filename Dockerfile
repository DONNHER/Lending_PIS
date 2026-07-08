FROM php:8.4-cli-alpine

# Set Composer to allow superuser (required for Docker root)
ENV COMPOSER_ALLOW_SUPERUSER=1

# Install system dependencies
RUN apk add --no-cache \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    git \
    postgresql-dev \
    icu-dev \
    linux-headers \
    libpq-dev \
    oniguruma-dev

# Install PHP extensions
RUN docker-php-ext-install pdo_pgsql pgsql bcmath zip intl

# Set working directory
WORKDIR /var/www/html

# Copy the Laravel backend files
COPY laravel_backend/ .

# Ensure standard Laravel folders exist and are writable
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache
RUN chmod -R 777 storage bootstrap/cache

# Remove local vendor to ensure fresh install
RUN rm -rf vendor

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install dependencies
# We use --ignore-platform-reqs to bypass strict version checks if the lock file is slightly ahead
RUN composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs

# Expose port (Railway provides $PORT)
EXPOSE 8080

# Start server
CMD php artisan migrate --force && echo "Starting Web Server on port $PORT..." && exec php -S 0.0.0.0:$PORT server.php
