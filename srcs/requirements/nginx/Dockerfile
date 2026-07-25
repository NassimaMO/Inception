FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl gettext-base

COPY ./conf/nginx.conf /etc/nginx/

COPY ./tools/entrypoint.sh /usr/local/bin/

ENTRYPOINT [ "sh", "/usr/local/bin/entrypoint.sh" ]

CMD [ "nginx", "-g", "daemon off;"]