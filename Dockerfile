FROM php:8.3-cli-alpine

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
    libpq

# Install PHP extensions
RUN docker-php-ext-configure intl
RUN docker-php-ext-install pdo_pgsql pgsql bcmath zip intl

# Set working directory
WORKDIR /var/www/html

# Copy the Laravel backend files
COPY laravel_backend/ .

# Ensure storage and bootstrap/cache directories exist and have proper permissions
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache
RUN chmod -R 777 storage bootstrap/cache

# IMPORTANT: Remove local vendor folder to ensure fresh install inside Linux
RUN rm -rf vendor

# Install Composer dependencies
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Expose port (Railway provides $PORT)
EXPOSE 8080

# Start server.
# We run migrations first, then start the PHP built-in server using server.php as the router.
# We use 'exec' to ensure PHP receives signals and Railway can monitor it.
CMD php artisan migrate --force && echo "Starting Web Server on port $PORT..." && exec php -S 0.0.0.0:$PORT server.php
