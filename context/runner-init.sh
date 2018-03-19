#!/bin/bash

set -a

CONFIG_DIR=/etc/gitlab-runner
OPTIONS=


_get_registered_tokens(){
    local tokens
    tokens=$(grep token $CONFIG_DIR/config.toml | cut -d\" -f2)
    echo $tokens
}

unregister(){
    gitlab-runner unregister --url $URL --token $1
}

unregister_all(){
    local token
    for token in $(_get_registered_tokens); do
        unregister $token
    done
}

# Ensure clean removal from gitlab in most cases
trap unregister_all SIGINT SIGTERM SIGHUP EXIT  # cannot be caught: SIGKILL SIGSTOP

# Ensure sudo rights
touch /etc/sudoers.d/gitlab-runner;
echo '%gitlab-runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/gitlab-runner;
chmod 0400 /etc/sudoers.d/gitlab-runner;

# Ensure docker run permissions
groupadd -g `stat -c"%g" /var/run/docker.sock` docker||true
usermod -a -G docker gitlab-runner

# You could use this in stack files environment tag:
#  - STACK={{index .Service.Labels "com.docker.stack.namespace"}}  # - STACK={{printf "%#v" .}}
# compose does not support go template
if [[ $STACK == {* ]]; then
    unset STACK
fi
# try to get the stack name
if [[ ! $STACK ]]; then
    STACK=$(docker inspect `hostname` --format '{{index .Config.Labels "com.docker.stack.namespace"}}')
fi

# For backwards compat keep the SERVICE var
SERVICE=${SERVICE:-${STACK:-${COMPOSE_PROJECT_NAME:?Any of SERVICE, STACK, COMPOSE_PROJECT_NAME is needed.}}_runner}

# Ensure config/secret is bound to myself
docker service update dashboards_portainer --config-add defaults.runner||true
docker service update dashboards_portainer --secret-add $SERVICE||true

# Source some variables
. /var/run/secrets/$SERVICE || true
. /defaults.runner || true

# Bartizado
DESCRIPTION=${SERVICE:+${SERVICE}_}`hostname`

# Misc options
if [[ $EXECUTOR == 'docker' ]]; then
    OPTIONS+=" --docker-image docker:latest --docker-volumes /var/run/docker.sock:/var/run/docker.sock"
fi

if [[ $TAG_LIST ]]; then
    OPTIONS+=" --tag-list $TAG_LIST"
fi


# Main
gitlab-runner register${OPTIONS} --executor $EXECUTOR -u $URL -r $TOKEN -n --description "$DESCRIPTION" --locked

/entrypoint $@




