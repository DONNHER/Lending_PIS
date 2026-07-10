#!/bin/sh
set -e # Exit on error
set -x # Print commands for debugging

# Ensure storage and bootstrap/cache are writable
# We do this at runtime to be sure
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Create .env if it doesn't exist (Railway usually provides vars via environment)
if [ ! -f .env ]; then
    echo "Creating .env from environment variables..."
    touch .env
fi

# Link storage
php artisan storage:link --force

# Run migrations (force for production)
echo "Running migrations..."
php artisan migrate --force

# Clear and Cache configuration
# Note: If you have issues, you can comment these out to debug
echo "Caching configuration..."
php artisan config:clear
php artisan route:clear
php artisan config:cache
php artisan route:cache

# Start the PHP server
# Using 'exec' ensures PHP becomes PID 1, which helps Railway monitor the process
echo "Starting server on port $PORT"
exec php -S 0.0.0.0:$PORT -t public
