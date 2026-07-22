FROM php:8.4-fpm-alpine

# Install system dependencies
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
    postgresql-client \
    icu-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libpq \
    gettext

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install pdo_pgsql pgsql bcmath zip intl gd exif pcntl

# Set working directory
WORKDIR /var/www/html

# Set Composer environment
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_PROCESS_TIMEOUT=2000

# Copy Laravel backend files
COPY laravel_backend/ .

# Install Composer dependencies
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts --ignore-platform-reqs

# COPY PRE-BUILT FLUTTER WEB INTO LARAVEL PUBLIC/PIS (Force Overwrite)
RUN mkdir -p /var/www/html/public/PIS
COPY build/web/ /var/www/html/public/PIS/

# Configuration Files
COPY scripts/railway/nginx.conf /etc/nginx/http.d/default.conf.template
COPY scripts/railway/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Permissions
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public/PIS
RUN chmod +x deploy.sh

# Entrypoint script to handle PORT env var for Nginx
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'envsubst "\$PORT" < /etc/nginx/http.d/default.conf.template > /etc/nginx/http.d/default.conf' >> /entrypoint.sh && \
    echo 'exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
