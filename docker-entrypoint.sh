#!/bin/bash
set -e

# Copy files to the web directory if they don't exist already
if ! [ -e index.php ]; then
  echo >&2 "OctoberCMS not found in $(pwd) - installing..."
  tar -xzf /usr/src/octobercms.tar.gz -C /var/www/html --strip 1 --keep-old-files
else
  echo >&2 "OctoberCMS found in $(pwd) - not installing"
fi

# if we have a clean repo then install
if ! [ -d vendor ]; then
  composer install --no-interaction --prefer-dist --no-scripts
fi

# Setup and export .env
php artisan october:env

# Generate random key for laravel
php artisan key:generate --force

# # Bring up the initial OctoberCMS database
#php artisan october:up

chown -R www-data:www-data /var/www/html

echo -e >&2 "\n\n------------------------------------------------------------------------------"
echo -e >&2 "OctoberCMS is ready."
echo -e >&2 "========================\n"
echo -e >&2 "Please check your docker environment variables and/or the .env file contents."
echo -e >&2 "If you are using a database, run 'php artisan october:up' to migrate it"
echo -e >&2 "------------------------------------------------------------------------------\n\n"

exec "$@"