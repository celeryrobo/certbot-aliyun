#!/bin/bash

NAME=certbot-aliyun
VESION=v$(date "+%Y%m%d%H%M%S")
IMAGE=${NAME}:${VESION}
TARGET=${NAME}.tar

build() {
    docker build --network host -t ${IMAGE} .
    source ~/.pyenv/bin/activate
    docker-squash ${IMAGE} -t ${IMAGE}
    deactivate
}

backup() {
    if [ -f ${TARGET} ]; then
        rm -f ${TARGET}
    fi
    docker save -o ${TARGET} ${IMAGE}
    yes | docker image prune
}

clean() {
    local EXEC=./clean.sh
    if [ -f ${EXEC} ]; then
        . ${EXEC}
    fi
}

main() {
    build && backup && clean
}

main
