#!/usr/bin/env bash
set -e -o pipefail

EXECUTOR=shell
IMAGE=webrunners/gitlab-runner-service:latest
MODE=
NAME=
NETWORK=bridge
REPLICAS=1
TOKEN=
DEBUG=

_error(){
    echo
    echo "[$BASH_LINENO] $@" 1>&2
    _usage
    exit 1
}

_usage(){
    echo "
    Usage:
        $0 [options] [--][RAW]

    Options:
        -e  Executor    default: shell
        -h  This help
        -i  Image       default: webrunners/gitlab-runner-service
        -m  Mode        [create|up|up-privileged|up-privileged-service]
        -n  Name
        -r  Replicas    default: 1
        -t  Token
        -v  Dry         Command output only
    RAW:
        Use doubledash if RAW starts with option
        Any RAW appends to command
    "
    echo
    exit 0
}


while getopts e:t:r:n:i:m:x:hv OPT; do
    case $OPT in
        t)
            TOKEN=$OPTARG
        ;;
        e)
            EXECUTOR=$OPTARG
        ;;
        r)
            REPLICAS=$OPTARG
        ;;
        n)
            NAME=$OPTARG
        ;;
        i)
            IMAGE=$OPTARG
        ;;
        m)
            MODE=$OPTARG
        ;;
        x)
            NETWORK=$OPTARG
        ;;
        h)
            _usage
        ;;
        v)
            DEBUG="echo "
        ;;
        *|?|:)
            echo Help: $0 -h
            exit 1
        ;;
    esac
done
shift $(($OPTIND-1))

create(){
    ${DEBUG}docker service create --replicas $REPLICAS --name $NAME $@
}
up(){
    ${DEBUG}docker service create --replicas $REPLICAS --name $NAME -e "TOKEN=$TOKEN" -e "EXECUTOR=$EXECUTOR" -e "URL=https://code.webrunners.de:443/ci" $@ $IMAGE
}
up-privileged-service(){
    # curl -sSL https://get.docker.com/ | sh
    ${DEBUG}docker service create --replicas=$REPLICAS --name $NAME --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock -e "TOKEN=$TOKEN" -e "EXECUTOR=$EXECUTOR" -e "URL=https://code.webrunners.de:443/ci" $@ $IMAGE
}
up-privileged(){
    ${DEBUG}docker run -d --restart always --network $NETWORK -v /var/run/docker.sock:/var/run/docker.sock --name $NAME -e "TOKEN=$TOKEN" -e "EXECUTOR=$EXECUTOR" -e "URL=https://code.webrunners.de:443/ci" $@ $IMAGE
}

[[ ! $MODE ]] && _error Mode required
[[ $MODE == up* ]] && [[ ! $NAME ]] && _error Name required
[[ $MODE == up* ]] && [[ ! $TOKEN ]] && _error Token required
[[ $MODE == up* ]] && [[ ! $NAME == gitlab-runner-* ]] && NAME="gitlab-runner-$NAME"

$MODE $@ || _usage
