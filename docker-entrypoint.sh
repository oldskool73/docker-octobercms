#!/bin/bash
set -e

INSTALL_TYPE=${OCTOBER_INSTALL_TYPE:-wizard}

function install_wizard {
  echo -e >&2 "Copying files..."
  tar -xzf /usr/src/octobercms.install.tar.gz -C /var/www/html --strip 1 --keep-old-files
  create_sqlite
  set_perms
  echo -e >&2 "\n\n------------------------------------------------------------------------------"
  echo -e >&2 "OctoberCMS install wizard is ready."
  echo -e >&2 "========================\n"
  echo -e >&2 "Please visit http://yoursite/install.php to install"
  echo -e >&2 "------------------------------------------------------------------------------\n\n"
}

function install_cli {
  echo -e >&2 "Copying files..."
  cp -rn /usr/src/octobercms/. /var/www/html
  php artisan key:generate --force
  sed -i "s/'disableCoreUpdates' => false,/'disableCoreUpdates' => true,/g" config/cms.php
  create_sqlite
  set_perms
  echo -e >&2 "\n\n------------------------------------------------------------------------------"
  echo -e >&2 "OctoberCMS is ready."
  echo -e >&2 "========================\n"
  echo -e >&2 "Please check your docker environment variables and/or the .env file contents."
  echo -e >&2 "------------------------------------------------------------------------------\n\n"
}

function install_none {
  echo >&2 "Skipping OctoberCMS install"  
}

function create_sqlite {
  if [ "${DB_CONNECTION:-sqlite}" = "sqlite" ] 
  then
    SQLITE_DB=${DB_DATABASE:-storage/database.sqlite}
    mkdir -p "$(dirname "$SQLITE_DB")"
    touch "$SQLITE_DB"
    chmod 666 "$SQLITE_DB"
  fi
}

function set_perms {
  chown -R www-data:www-data /var/www/html
}

case "$INSTALL_TYPE" in
  cli)
    install_cli
    ;;
  wizard)
    install_wizard
    ;;
  none)
    install_none
    ;;
  *)
    echo >&2 "ERROR : Unknown install type '$INSTALL_TYPE', use 'cli','wizard' or 'none'"
    exit 1
esac    

exec "$@"