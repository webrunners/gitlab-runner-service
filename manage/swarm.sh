#!/usr/bin/env bash
set -e -o pipefail

cd "$(dirname "$0")"

DEBUG=
MODE=service
QUIET=
SERVICE_MASTER_NODE=$NODE
if [[ ! $SERVICE_MASTER_NODE ]]; then
    . .conf
    SERVICE_MASTER_NODE=$NODE
    if [[ ! $SERVICE_MASTER_NODE ]]; then
        echo Set NODE
        exit 1
    fi
fi
[[ ! $SERVICE_MASTER_NODE == *.webrunners.de ]] && SERVICE_MASTER_NODE=${SERVICE_MASTER_NODE}.webrunners.de

manage="./$(basename $0)"

_error(){
    local ERROR="$@"
    ERROR=${ERROR:='unexpected error'}
    echo
    echo "[$BASH_LINENO] $ERROR" 1>&2
    echo Help: $0 -h
    exit 1
}

_usage(){
    echo "
    Usage:
        $0 [options] [--][RAW]

    Options:
        -q  Quiet       Suppress informational output
        -m  Mode        default: service [docker|list-containers|list-services|runner|service|ssh]
        -n  Name        The name of the service to manage
        -v  Dry         Command output only

    RAW:
        Use the doubledash -- if RAW starts with option.
        For mode=runner you have to use the -- before any runner options.

    Modes:
        docker          Execute docker binary on node
        list-containers List connection infos for services containers
        list-services   service ls
        runner          Execute runner.sh on node
        service         Execute docker service command on node
        ssh             Plain ssh
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
            MODE=$OPTARG;
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


_ssh(){
    [[ $QUIET ]] || echo NODE: $SERVICE_MASTER_NODE
    ${DEBUG}ssh "${@}"
}


if [[ $MODE == runner ]]; then
    _ssh -qt $SERVICE_MASTER_NODE runner ${@}

elif [[ $MODE == docker ]]; then
    _ssh -qt $SERVICE_MASTER_NODE docker ${@}

elif [[ $MODE == service ]]; then
    _ssh -qt $SERVICE_MASTER_NODE docker service ${@}

elif [[ $MODE == ssh ]]; then
    _ssh -qt $SERVICE_MASTER_NODE ${@}

elif [[ $MODE == list-services ]]; then
    if [[ $@ ]]; then
        _error Please provide no arguments. Mode \'list-services\' just executes \`docker service ls\` on $SERVICE_MASTER_NODE
    fi
    _ssh -qt $SERVICE_MASTER_NODE docker service ls

elif [[ $MODE == list-containers ]]; then
    [[ ! $SERVICE ]] && _error NAME required
    [[ $DEBUG ]] && _error Dry mode not available for list-containers
    CONTAINERS=(`$manage -m ssh docker service ps -f desired-state=running $SERVICE|grep $SERVICE|awk '{ print $2 "." $1 }'||_error No containers for $SERVICE`)
    NODES=(`$manage -m ssh docker service ps -f desired-state=running $SERVICE|grep $SERVICE|awk '{ print $4 }'||_error No nodes`)
    IDS=(`for NUM in $(seq 0 $((${#CONTAINERS[@]}-1))); do NODE=${NODES[$NUM]} $manage -m ssh -q docker inspect --format="{{.Id}}" ${CONTAINERS[$NUM]}; done`)

    for NUM in $(seq 0 $((${#CONTAINERS[@]}-1))); do [[ $QUIET ]] || echo $NUM; ID=`echo ${IDS[$NUM]}|cut -c-8`; echo NAME=${CONTAINERS[$NUM]} ID=$ID NODE=${NODES[$NUM]} $manage -m ssh docker exec -it $ID bash; NODE=${NODES[$NUM]} $manage -m ssh -qv docker exec -it $ID bash; echo; done
else
    _error unknown mode: $MODE
fi
