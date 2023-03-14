FROM ubuntu:22.04

LABEL maintainer "Francisco-Javier Ramón"

ENV DESTINATION google.com
ENV INTERVAL 2

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y \
        curl \
        dnsutils \
        --no-install-recommends \
        && rm -rf /var/lib/apt/lists/*

WORKDIR /work

COPY repeat.sh .

CMD ./repeat.sh dig ${DESTINATION} +short
