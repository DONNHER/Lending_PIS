FROM php:8.4-fpm-alpine

# Install system dependencies, PostgreSQL dev libraries, and tools
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    git \
    postgresql-dev \
    icu-dev

# Install PHP extensions
RUN docker-php-ext-configure intl
RUN docker-php-ext-install pdo_pgsql pgsql bcmath zip intl

# Set working directory
WORKDIR /var/www/html

# Copy the Laravel backend files
COPY laravel_backend/ .

# IMPORTANT: Remove any local 'vendor' folder that might have been copied.
# This prevents "Could not scan for classes" errors caused by local Windows symlinks.
RUN rm -rf vendor

# Install Composer dependencies
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install dependencies (freshly, inside the Linux container)
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts --ignore-platform-req=php+

# Ensure proper Laravel storage permissions
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Expose port 80 for web traffic
EXPOSE 80

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=80"]
