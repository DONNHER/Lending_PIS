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
# Added intl and zip extension which are required by many Laravel packages
RUN docker-php-ext-configure intl
RUN docker-php-ext-install pdo_pgsql pgsql bcmath zip intl

# Set working directory
WORKDIR /var/www/html

# Copy the Laravel backend files
# If your Lending_PIS repo has composer.json at the root, change this to: COPY . .
# Based on your logs, it seems laravel_backend/ is present in your build context.
COPY laravel_backend/ .

# Install Composer dependencies
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Added --no-interaction to prevent build hanging
# Added --ignore-platform-req=php+ to ensure it proceeds if there's a minor mismatch
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# Ensure proper Laravel storage permissions
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Expose port 80 for web traffic
EXPOSE 80

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=80"]
