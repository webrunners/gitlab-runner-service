#!/bin/bash

# relies on exported EXECUTOR URL TOKEN

CONFIG_DIR=/etc/gitlab-runner
OPTIONS=
TAG_LIST=


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

trap unregister_all SIGINT SIGTERM SIGHUP EXIT # cannot be caught: SIGKILL SIGSTOP

[[ $SERVICE ]] && [[ -f /var/run/secrets/$SERVICE ]] && . /var/run/secrets/$SERVICE
[[ $DESCRIPTION ]] || DESCRIPTION=${SERVICE}_`hostname`
[[ $EXECUTOR == 'docker' ]] && OPTIONS+=" --docker-image docker:latest --docker-volumes /var/run/docker.sock:/var/run/docker.sock"
[[ $TAG_LIST ]] && OPTIONS+=" --tag-list $TAG_LIST"

touch /etc/sudoers.d/gitlab-runner;
echo '%gitlab-runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/gitlab-runner;
chmod 0400 /etc/sudoers.d/gitlab-runner;
usermod -a -G docker gitlab-runner

gitlab-runner register${OPTIONS} --executor $EXECUTOR -u $URL -r $TOKEN -n --description "$DESCRIPTION" --locked

/entrypoint $@




