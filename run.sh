#!/usr/bin/env bash
set -e -o pipefail

DEBUG=
MODE=ssh
QUIET=
SERVICE_MASTER_NODE=${NODE:=dnet01.webrunners.de}
[[ ! $SERVICE_MASTER_NODE == *.webrunners.de ]] && SERVICE_MASTER_NODE=${SERVICE_MASTER_NODE}.webrunners.de


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
        -q  Quiet
        -m  Mode        default: ssh [ssh|container]
        -n  Name
        -v  Dry         Command output only
    "
    echo
    exit 0
}


while getopts hqvm:n: OPT; do
    case $OPT in
        q)
            QUIET=yes
        ;;
        m)
            MODE=$OPTARG
        ;;
        n)
            SERVICE=$OPTARG
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



if [[ $MODE == ssh ]]; then
    [[ $QUIET ]] || echo NODE: $SERVICE_MASTER_NODE
    ${DEBUG}ssh -qt $SERVICE_MASTER_NODE "${@}"
elif [[ $MODE == container ]]; then
    [[ ! $SERVICE ]] && _error NAME required
    CONTAINERS=(`./run.sh docker service ps -f desired-state=running $SERVICE|grep $SERVICE|awk '{ print $2 "." $1 }'`)
    NODES=(`./run.sh docker service ps -f desired-state=running $SERVICE|grep $SERVICE|awk '{ print $4 }'`)
    IDS=(`for NUM in $(seq 0 $((${#CONTAINERS[@]}-1))); do NODE=${NODES[$NUM]} ./run.sh -q docker inspect --format="{{.Id}}" ${CONTAINERS[$NUM]}; done`)

    for NUM in $(seq 0 $((${#CONTAINERS[@]}-1))); do ID=`echo ${IDS[$NUM]}|cut -c-8`; echo NAME=${CONTAINERS[$NUM]} ID=$ID NODE=${NODES[$NUM]} ./run.sh docker exec -it $ID bash; ./run.sh -v docker exec -it $ID bash; echo; done
else
    echo unknown mode: $MODE
    exit 1
fi
