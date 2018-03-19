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
STACK=$(docker inspect `hostname` --format '{{index .Config.Labels "com.docker.stack.namespace"}}')
if [[ ! $SERVICE ]]; then
    SERVICE=$(docker inspect `hostname` --format '{{index .Config.Labels "com.docker.swarm.service.name"}}')
fi
DESCRIPTION=${SERVICE:?SERVICE var required}_`hostname`

# Ensure config/secret is bound to myself
docker service update $SERVICE --config-add runner||true
docker service update $SERVICE --secret-add $SERVICE||true

# Source some variables
. /var/run/secrets/$SERVICE || true
. /runner || true

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




