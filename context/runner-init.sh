#!/bin/bash

__bool(){ [[ "$(echo ${1:-0}|tr a-z A-Z)" =~ ^(YES|JA|TRUE|[YJ1])$ ]] || return 1; }

unregister(){
    gitlab-runner unregister --all-runners
}


# Ensure clean removal from gitlab in most cases
trap unregister SIGINT SIGTERM SIGHUP EXIT  # cannot be caught: SIGKILL SIGSTOP

# Ensure docker run permissions
groupadd -g `stat -c"%g" /var/run/docker.sock` docker || true
usermod -a -G docker gitlab-runner


if [[ $DEBUG ]]; then
    tail -f /var/log/lastlog
fi


## Build runners name

# Get the stackname
STACK="$(docker inspect $HOSTNAME --format '{{index .Config.Labels "com.docker.stack.namespace"}}')"
# Get the name of the node
if [[ ! "${NODE:-}" ]]; then
    NODE_ID="$(docker inspect $HOSTNAME --format '{{index .Config.Labels "com.docker.swarm.node.id"}}')"
    NODE="$(docker node inspect $NODE_ID --format '{{.Description.Hostname}}')"
    [[ ! $NODE ]] && NODE="$(curl myip.webrunners.de)"
fi
# Get the name of the service
# You could use this under stack files environment tag:
#  - STACK={{index .Service.Labels "com.docker.stack.namespace"}}  # - STACK={{printf "%#v" .}}
SERVICE=$(docker inspect $HOSTNAME --format '{{index .Config.Labels "com.docker.swarm.service.name"}}')

: ${STACK:-$SERVICE}
: ${NODE:?Error: NODE required. This might not be a docker swarm}
: ${SERVICE:?Error: SERVICE required. This might not be a docker swarm}

__bool ${DISABLE_SELFUPDATE:-1} && DISABLE_SELFUPDATE=1 || DISABLE_SELFUPDATE=

# Baptize
DESCRIPTION=${SERVICE}_${HOSTNAME}@$NODE

## Ensure configs/secrets

if [[ $DISABLE_SELFUPDATE ]]; then
    echo DISABLE_SELFUPDATE: Disabled self update

    # Source some variables
    if [[ ! "$URL" ]]; then
        if [[ "$URL_CONFIG" ]]; then
            URL_CONFIG_FILE=$(docker inspect $SERVICE | jq ".[]|.Spec.TaskTemplate.ContainerSpec.Configs|.[]|select(.ConfigName==\"$URL_CONFIG\")|.File.Name" -r)
        fi
        if ! echo $URL_CONFIG_FILE | grep -q  $URL_CONFIG; then
            echo URL_CONFIG not found. Check stack file for configs
            exit 1
        fi
        URL="$(< $URL_CONFIG_FILE)"
    fi

    if [[ ! "$TOKEN" ]]; then
        if [[ $TOKEN_SECRET ]]; then
            TOKEN_SECRET_FILE=$(docker inspect $SERVICE | jq ".[]|.Spec.TaskTemplate.ContainerSpec.Secrets|.[]|select(.SecretName==\"$TOKEN_SECRET\")|.File.Name" -r)
        fi
        if ! echo $TOKEN_SECRET_FILE | grep -q  $TOKEN_SECRET; then
            echo TOKEN_SECRET not found. Check stack file for configs
            exit 1
        fi
        TOKEN="$(< $TOKEN_SECRET_FILE)"
    fi

else
    dCONFIG=$(docker config ls --format {{.Name}}|grep '^runner.defaults$') || true
    dSECRET=$(docker secret ls --format {{.Name}}|grep "^${STACK}$") || true

    VOLUMES_OPTION=()
    VOLUMES=${VOLUMES// /}
    VOLUMES=(${VOLUMES//,/ })
    if [[ "$VOLUMES" ]]; then
        for volume in ${VOLUMES[@]}; do
            VOLUMES_OPTION+=("--mount-add type=volume,source=$volume,target=/$volume")
        done
    fi

    echo -n "Selfupdating stack: $STACK. service: $SERVICE"
    set -x
    docker service update $SERVICE -d ${VOLUMES_OPTION:+ ${VOLUMES_OPTION[@]}}${dCONFIG:+ --config-add $dCONFIG}${dSECRET:+ --secret-add $dSECRET} || true
    set +x

    # Source some variables
    if test -f /var/run/secrets/$STACK; then
        echo /var/run/secrets/$STACK found
        . /var/run/secrets/$STACK
    else
        echo Warning: /var/run/secrets/$STACK missing
    fi

    if test -f /runner.defaults; then
        echo /runner.defaults found
        . /runner.defaults
    else
        echo Warning: /runner.defaults missing
    fi
fi

## Startup sequence

export CI_SERVER_URL=${URL:-${CI_SERVER_URL:?One of URL, CI_SERVER_URL required}}
export REGISTRATION_TOKEN=${TOKEN:-${REGISTRATION_TOKEN:-${CI_SERVER_TOKEN:?One of TOKEN, REGISTRATION_TOKEN, CI_SERVER_TOKEN required}}}
export RUNNER_EXECUTOR=${EXECUTOR:-${RUNNER_EXECUTOR:-shell}}

# Misc options
if [[ "$RUNNER_EXECUTOR" == 'docker' ]]; then
    OPTIONS+=" --docker-image docker:latest --docker-volumes /var/run/docker.sock:/var/run/docker.sock"
fi

if [[ "$TAG_LIST" ]]; then
    OPTIONS+=" --tag-list ${TAG_LIST// /,}"
fi

# Main
gitlab-runner register${OPTIONS:+ $OPTIONS} -n --description "$DESCRIPTION" --locked  # --executor ${EXECUTOR:-shell} -u ${URL:?URL required} -r ${TOKEN:?TOKEN required}

# Must not be exec'ed. Otherwise the trap won't unregister the runner
/entrypoint $@
