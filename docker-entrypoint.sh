#!/bin/bash
set -e

echo "Running database migrations..."
php artisan migrate --force

# Check if database is empty (no users table or it's empty)
echo "Checking if database needs seeding..."
TABLE_COUNT=$(php artisan tinker --execute="echo \DB::table('users')->count();" 2>/dev/null || echo "0")
if [ "$TABLE_COUNT" = "0" ]; then
  echo "Database is empty, running seeders..."
  php artisan db:seed --force
else
  echo "Database already has data, skipping seeding."
fi

echo "Starting Apache..."
exec apache2-foreground
