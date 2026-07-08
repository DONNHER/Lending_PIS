#!/bin/sh
echo "--- DEBUG: Starting Laravel Debug Script ---"
echo "Current Directory: $(pwd)"
echo "PHP Version: $(php -v | head -n 1)"
echo "Port: ${PORT:-8080}"

echo "--- Checking Laravel Environment ---"
php artisan --version
php artisan env

echo "--- Checking Directory Permissions ---"
ls -ld storage bootstrap/cache
ls -F

echo "--- Running Migrations ---"
php artisan migrate --force

echo "--- Checking Routes ---"
php artisan route:list

echo "--- Starting PHP Server ---"
# Using -d display_errors=On to catch startup crashes
php -d display_errors=On -S 0.0.0.0:${PORT:-8080} -t public
