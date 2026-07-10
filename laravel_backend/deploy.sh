#!/bin/sh
set -x

echo "--- Deployment Starting ---"

# 1. Fix Permissions
echo "Setting permissions..."
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# 2. Force Clear Cache (In case of corrupt build artifacts)
echo "Clearing bootstrap cache..."
rm -f bootstrap/cache/*.php

# 3. Check PHP and Extensions
php -v
php -m

# 4. Try to run Artisan (This will now show the REAL error if it fails)
echo "Testing Artisan connection..."
php artisan --version

# 5. Link Storage
echo "Linking storage..."
php artisan storage:link --force

# 6. Run Migrations
echo "Running migrations..."
php artisan migrate --force

# 7. Start the server
echo "Starting Laravel server on port $PORT..."
exec php artisan serve --host=0.0.0.0 --port=$PORT
