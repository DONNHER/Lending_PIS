#!/bin/sh
set -x

echo "--- Deployment Starting ---"

# 1. Fix Permissions
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# 2. Clear bootstrap cache files that might be corrupted from local Windows dev
rm -f bootstrap/cache/*.php

# 3. Create storage link (ignore error if already exists)
php artisan storage:link --force || echo "Storage link failed, continuing..."

# 4. Run Migrations (ignore error if DB is still setting up)
echo "Running migrations..."
php artisan migrate --force || echo "Migration failed, check DB credentials."

# 5. Start the server
echo "Starting PHP server on port $PORT..."
# Using php -S directly is the most stable way to ensure we see errors
exec php -d display_errors=1 -S 0.0.0.0:$PORT -t public
