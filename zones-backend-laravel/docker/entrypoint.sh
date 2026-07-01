#!/bin/sh
set -e

PORT="${PORT:-8000}"

if [ -z "$APP_KEY" ]; then
  echo "ERROR: APP_KEY is not set. Generate one with: php artisan key:generate --show"
  exit 1
fi

# Free Render: paste Aiven ca.pem into AIVEN_CA_PEM (no Secret Files / paid upload needed)
CA_PATH="/var/www/html/storage/aiven-ca.pem"
if [ -n "$AIVEN_CA_PEM" ]; then
  printf '%s\n' "$AIVEN_CA_PEM" > "$CA_PATH"
  export MYSQL_ATTR_SSL_CA="${MYSQL_ATTR_SSL_CA:-$CA_PATH}"
  echo "Aiven CA certificate written from AIVEN_CA_PEM"
elif [ -n "$MYSQL_ATTR_SSL_CA" ] && [ ! -f "$MYSQL_ATTR_SSL_CA" ]; then
  echo "ERROR: MYSQL_ATTR_SSL_CA is set but file not found: $MYSQL_ATTR_SSL_CA"
  echo "On Render Free: remove MYSQL_ATTR_SSL_CA and paste ca.pem content into AIVEN_CA_PEM instead."
  exit 1
fi

php artisan config:cache
php artisan route:cache
php artisan view:cache

php artisan migrate --force
php artisan db:seed --class=RoleSeeder --force --no-interaction
php artisan storage:link 2>/dev/null || true

(
  while true; do
    php artisan schedule:run --verbose --no-interaction || true
    sleep 60
  done
) &

exec php artisan serve --host=0.0.0.0 --port="$PORT"
