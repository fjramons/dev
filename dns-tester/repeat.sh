#!/bin/bash

export INTERVAL=${INTERVAL:-2}

while true;
do
    #dig www.oracle.com +short
    printf "${HOSTNAME}: %(%m-%d %H:%M:%S)T --> "
    "$@"
    sleep ${INTERVAL}
done
