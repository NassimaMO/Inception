FROM debian:bookworm

RUN apt-get update && apt-get install -y mariadb-server   

COPY ./conf/mariadb.cnf /etc/mysql/mariadb.conf.d/

COPY ./tools/entrypoint.sh /usr/local/bin/

ENTRYPOINT [ "sh", "/usr/local/bin/entrypoint.sh" ]

CMD [ "mysqld", "--user=mysql" ]