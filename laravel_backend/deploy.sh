#!/bin/sh
set -x

echo "--- Deployment Starting ---"

# 1. Fix Permissions
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# 2. Clear all caches
php artisan config:clear
php artisan cache:clear
php artisan route:clear
rm -f bootstrap/cache/*.php

# 3. Run Migrations
echo "Running migrations..."
php artisan migrate --force

# 4. Create storage link
php artisan storage:link --force

# 5. Start the server
echo "Starting PHP server on port $PORT..."
exec php artisan serve --host=0.0.0.0 --port=$PORT
