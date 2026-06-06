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
    libzip-dev \
    git \
    postgresql-dev

# Install PHP extensions
# Added zip extension which is often required by composer to extract packages
RUN docker-php-ext-install pdo_pgsql pgsql bcmath zip

# Set working directory
WORKDIR /var/www/html

# Copy the Laravel backend files
# Note: If you push ONLY the contents of 'laravel_backend' to your Lending_PIS repo,
# change this to: COPY . .
# If you push the entire project folder, keep it as: COPY laravel_backend/ .
COPY laravel_backend/ .

# Install Composer dependencies
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Added --no-interaction to prevent build hanging on prompts
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Ensure proper Laravel storage permissions
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Expose port 80 for web traffic
EXPOSE 80

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=80"]
