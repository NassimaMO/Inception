#!/bin/bash

rm -f /var/www/html/index.nginx-debian.html

until mysqladmin ping -h mariadb -u "${MYSQL_USER}" -p"$(cat /run/secrets/db_password)" --silent; do
    echo "Waiting for MariaDB..."
    sleep 1
done

if [ ! -f /var/www/html/wp-config.php ]; then
    ADMIN_PASS=$(grep ADMIN_PASSWORD /run/secrets/credentials | cut -d'=' -f2)
    REVIEWER_PASS=$(grep REVIEWER_PASSWORD /run/secrets/credentials | cut -d'=' -f2)
    wp core download --allow-root
    wp config create \
    --dbname="${MYSQL_DB}" \
    --dbuser="${MYSQL_USER}" \
    --dbpass="$(cat /run/secrets/db_password)" \
    --dbhost=mariadb \
    --allow-root
    wp core install \
        --url="${DOMAIN_NAME}" \
        --title="..." \
        --admin_user="nassima" \
        --admin_password="${ADMIN_PASS}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --allow-root
    wp user create \
        reviewer user@email.com \
        --role=author \
        --user_pass="${REVIEWER_PASS}" \
        --allow-root

fi

exec "$@"
