#!/bin/sh

# Ensure storage and bootstrap/cache are writable
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Link storage
php artisan storage:link --force

# Run migrations (force for production)
echo "Running migrations..."
php artisan migrate --force

# Optimize Laravel for production
echo "Caching configuration and routes..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start the PHP server with the Railway dynamic port
echo "Starting server on port $PORT"
php artisan serve --host=0.0.0.0 --port=$PORT
