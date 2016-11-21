#!/usr/bin/env bash
set -e -o pipefail

QUIET=
SERVICE_MASTER_NODE=${NODE:=dnet01.webrunners.de}
[[ ! $SERVICE_MASTER_NODE == *.webrunners.de ]] && SERVICE_MASTER_NODE=${SERVICE_MASTER_NODE}.webrunners.de

while getopts q OPT; do
    case $OPT in
        q)
            QUIET=yes
        ;;
    esac
done
shift $(($OPTIND-1))

[[ $QUIET ]] || echo NODE: $SERVICE_MASTER_NODE
ssh -qt $SERVICE_MASTER_NODE "${@}"
