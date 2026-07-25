#!/bin/bash

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d "/var/lib/mysql/${MYSQL_DB}" ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
    DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
    mysql_install_db --user=mysql

    mysqld_safe --skip-networking &
    until mysqladmin ping --silent; do
       sleep 1
    done

    mysql -e "CREATE DATABASE ${MYSQL_DB};"
    mysql -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
    mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'%';"
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';"
    mysql -e "FLUSH PRIVILEGES;"

    mysqladmin -u root -p"${DB_ROOT_PASSWORD}" shutdown
fi

exec "$@"
