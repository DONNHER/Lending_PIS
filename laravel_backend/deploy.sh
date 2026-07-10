#!/bin/sh
# Do NOT use set -e yet so we can see all error messages
set -x

echo "--- Deployment Starting ---"

# 1. Check if APP_KEY is set
if [ -z "$APP_KEY" ]; then
    echo "FATAL ERROR: APP_KEY is not set in Railway Variables."
    echo "Please add APP_KEY to your Railway project settings."
    # We don't exit here so we can see other errors, but Laravel WILL fail.
fi

# 2. Fix Permissions
echo "Setting permissions..."
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# 3. Try to run Artisan and capture ANY error
echo "Testing Artisan connection..."
php artisan --version 2>&1 || echo "Artisan failed to boot. Check your environment variables."

# 4. Storage Link (often where it crashes if .env is missing)
echo "Linking storage..."
php artisan storage:link --force 2>&1

# 5. Run Migrations
echo "Running migrations..."
php artisan migrate --force 2>&1

# 6. Start the server using the dynamic Railway port
echo "Starting Laravel server on port $PORT..."
# Using php artisan serve is usually fine, but let's ensure it doesn't background
exec php artisan serve --host=0.0.0.0 --port=$PORT
