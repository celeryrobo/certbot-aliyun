#!/bin/bash

lst() {
    docker images -f "reference=certbot-*" -q
}

main() {
    lst | xargs -i docker rmi {}
}

main
