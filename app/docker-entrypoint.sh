#!/bin/bash
set -e

echo "Running database migrations..."
php artisan migrate --force

# Only seed if flag file exists (touch /tmp/need-seed to trigger seeding)
if [ -f /tmp/need-seed ]; then
  echo "Seed flag detected, running seeders..."
  php artisan db:seed --force
  rm /tmp/need-seed
else
  echo "No seed flag, skipping seeding (create /tmp/need-seed to force seed)."
fi

echo "Starting Apache..."
exec apache2-foreground
