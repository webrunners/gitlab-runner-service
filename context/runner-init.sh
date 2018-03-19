#!/bin/bash

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
touch /etc/sudoers.d/gitlab-runner
echo '%gitlab-runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/gitlab-runner
chmod 0400 /etc/sudoers.d/gitlab-runner

# Ensure docker run permissions
groupadd -g `stat -c"%g" /var/run/docker.sock` docker||true
usermod -a -G docker gitlab-runner


CONFIG_DIR=/etc/gitlab-runner
STACK=$(docker inspect $HOSTNAME --format '{{index .Config.Labels "com.docker.stack.namespace"}}')

# You could use this under stack files environment tag:
#  - STACK={{index .Service.Labels "com.docker.stack.namespace"}}  # - STACK={{printf "%#v" .}}
if [[ ! "${SERVICE:-}" ]]; then
    SERVICE=$(docker inspect $HOSTNAME --format '{{index .Config.Labels "com.docker.swarm.service.name"}}')
fi

: ${SERVICE:?SERVICE var required}
DESCRIPTION=${SERVICE}_${HOSTNAME}

# Ensure config/secret is bound to myself
dCONFIG=$(docker config ls --format {{.Name}}|grep '^runner$')
dSECRET=$(docker secret ls --format {{.Name}}|grep "^${SERVICE}$")
dSECRET_ALT=$(docker secret ls --format {{.Name}}|grep "^${STACK}$")
docker service update $SERVICE -d ${dCONFIG:+--config-rm $dCONFIG --config-add $dCONFIG}${dSECRET:+ --secret-rm $dSECRET --secret-add $dSECRET}${dSECRET_ALT:+ --secret-rm $dSECRET_ALT --secret-add $dSECRET_ALT}

# Source some variables
. /var/run/secrets/$STACK || true
. /var/run/secrets/$SERVICE || true
. /runner || true

export CI_SERVER_URL=${URL:-${CI_SERVER_URL:?CI_SERVER_URL required}}
export CI_SERVER_TOKEN=${TOKEN:-${CI_SERVER_TOKEN:?CI_SERVER_TOKEN required}}
export RUNNER_EXECUTOR=${EXECUTOR:-${RUNNER_EXECUTOR:-shell}}

# Misc options
if [[ $EXECUTOR == 'docker' ]]; then
    OPTIONS+=" --docker-image docker:latest --docker-volumes /var/run/docker.sock:/var/run/docker.sock"
fi

if [[ $TAG_LIST ]]; then
    OPTIONS+=" --tag-list ${TAG_LIST// /,}"
fi


# Main
gitlab-runner register${OPTIONS} -n --description "$DESCRIPTION" --locked  # --executor ${EXECUTOR:-shell} -u ${URL:?URL required} -r ${TOKEN:?TOKEN required}

/entrypoint $@
