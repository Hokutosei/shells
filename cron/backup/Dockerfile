FROM alpine:3.3

RUN apk update
RUN apk add ca-certificates

RUN echo 'http://dl-3.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories
RUN apk upgrade --update
RUN apk add mongodb-tools docker
RUN mkdir /bkp

COPY backup.sh /backup.sh
COPY cronfile /var/spool/cron/crontabs/root
CMD crond -l 2 -f