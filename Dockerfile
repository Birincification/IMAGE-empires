FROM openjdk:15-alpine

RUN apk add bash sysstat

ADD scripts /home/scripts
ADD software /home/software
