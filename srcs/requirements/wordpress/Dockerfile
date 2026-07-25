FROM debian:bookworm

RUN apt-get update && apt-get install -y php-fpm curl php-mysql mariadb-client

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

COPY ./tools/entrypoint.sh /usr/local/bin/

COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

WORKDIR /var/www/html

ENTRYPOINT [ "sh", "/usr/local/bin/entrypoint.sh" ]

CMD [ "php-fpm8.2", "-F" ]
