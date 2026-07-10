#!/bin/sh
# Do not use set -e so we can see all errors
set -x

echo "--- Deployment Starting ---"

# 1. Fix Permissions
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# 2. Clear all caches to ensure a clean boot
php artisan config:clear
php artisan cache:clear
php artisan route:clear
rm -f bootstrap/cache/*.php

# 3. Test Database Connection (This is the most common failure point)
echo "Testing Database Connection..."
php -r "try { new PDO('pgsql:host='.getenv('DB_HOST').';port='.getenv('DB_PORT').';dbname='.getenv('DB_DATABASE'), getenv('DB_USERNAME'), getenv('DB_PASSWORD')); echo 'Database Connection Successful!'; } catch (Exception \$e) { echo 'Database Connection Failed: ' . \$e->getMessage(); exit(1); }"

# 4. Run Migrations
echo "Running migrations..."
php artisan migrate --force

# 5. Start the server using the RAW PHP server
# We use 'exec' so PHP becomes the main process.
# We add -d display_errors=1 to catch boot crashes.
echo "Starting PHP server on port $PORT..."
exec php -d display_errors=1 -S 0.0.0.0:$PORT -t public
