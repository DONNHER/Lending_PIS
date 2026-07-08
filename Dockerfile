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

# Remove local .env to ensure Railway variables are used
RUN rm -f .env

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

# Expose port (Railway provides $PORT)
EXPOSE 8080

# Start server and run migrations.
# We use || true to ensure the server starts even if migrations fail,
# which helps in debugging connectivity issues from within the app.
CMD ["sh", "-c", "echo 'Starting deployment script...'; php artisan migrate --force; echo 'Migrations finished. Starting PHP server on port ${PORT:-8080}...'; php -S 0.0.0.0:${PORT:-8080} -t public"]
