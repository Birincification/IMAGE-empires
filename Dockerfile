FROM openjdk:15-alpine

RUN apk add bash

ADD scripts /home/scripts
ADD software /home/software
