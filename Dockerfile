FROM php:8.2-fpm-alpine

# Install system dependencies, PostgreSQL dev libraries, and tools
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    postgresql-dev

# Install the correct PHP extensions for PostgreSQL (pgsql and pdo_pgsql)
RUN docker-php-ext-install pdo_pgsql pgsql bcmath

# Set working directory
WORKDIR /var/www/html

# Copy the Laravel backend files from the subdirectory
COPY laravel_backend/ .

# Install Composer dependencies
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader

# Ensure proper Laravel storage permissions
# Creating necessary directories to avoid permission issues
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Expose port 80 for web traffic
EXPOSE 80

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=80"]
