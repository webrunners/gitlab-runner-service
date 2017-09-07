#!/bin/bash

# relies on exported EXECUTOR URL TOKEN

CONFIG_DIR=/etc/gitlab-runner
OPTIONS=

trap unregister_all SIGINT SIGTERM SIGHUP  # cannot be caught: SIGKILL SIGSTOP

_get_registered_tokens(){
    local tokens
    tokens=$(cat $CONFIG_DIR/config.toml | grep token | cut -d\" -f2)
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

[[ $SERVICE ]] && [[ -f /var/run/secrets/$SERVICE ]] && . /var/run/secrets/$SERVICE
[[ $DESCRIPTION ]] || DESCRIPTION=${SERVICE}_`hostname`

touch /etc/sudoers.d/gitlab-runner;
echo '%gitlab-runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/gitlab-runner;
chmod 0400 /etc/sudoers.d/gitlab-runner;

[[ $EXECUTOR == 'docker' ]] && OPTIONS=" --docker-image docker:latest --docker-volumes /var/run/docker.sock:/var/run/docker.sock"


gitlab-runner register${OPTIONS} --executor $EXECUTOR -u $URL -r $TOKEN -n --description "$DESCRIPTION" --locked

/entrypoint $@




