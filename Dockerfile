FROM openjdk:14-alpine

RUN apk add bash

ADD scripts /home/scripts
ADD software /home/software
