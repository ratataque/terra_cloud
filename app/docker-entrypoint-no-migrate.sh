#!/bin/bash
set -e

# FAST STARTUP - No migrations, no seeding
# Run migrations manually: docker exec app php artisan migrate --force

echo "Starting Apache (migrations disabled for fast startup)..."
exec apache2-foreground
