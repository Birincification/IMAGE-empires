FROM openjdk:15-alpine

RUN apk add bash sysstat
RUN apk update
RUN apk upgrade

ADD scripts /home/scripts
ADD software /home/software
