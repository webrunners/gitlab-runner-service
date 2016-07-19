#!/bin/bash

EXECUTOR=${1:-$EXECUTOR}
URL=${2:-$URL}
TOKEN=${3:-$TOKEN}
CONFIG_DIR=/etc/gitlab-runner

trap unregister_all SIGINT SIGTERM ERR EXIT SIGHUP  # cannot be caught: SIGKILL SIGSTOP

_get_registered_tokens(){
    local tokens
    tokens=$(cat $CONFIG_DIR/config.toml | grep token | cut -d\" -f2)
    echo $tokens
}

unregister(){
    gitlab-runner unregister --url $URL --token $TOKEN $@
}

unregister_all(){
    local token
    for token in $(_get_registered_tokens); do
        TOKEN=$token
        unregister
    done
}


echo '%gitlab-runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/gitlab-runner;

gitlab-runner register --executor $EXECUTOR -u $URL -r $TOKEN -n
/usr/bin/dumb-init /entrypoint run --user=gitlab-runner --working-directory=/home/gitlab-runner
