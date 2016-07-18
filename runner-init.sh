EXECUTOR=$1
URL=$2
TOKEN=$3
CONFIG_DIR=/etc/gitlab-runner

trap unregister_all SIGINT SIGTERM ERR EXIT

_get_registered_tokens(){
    local tokens
    tokens=$(cat $CONFIG_DIR/config.toml | grep token | cut -d\" -f2)
    echo $tokens
}

unregister(){
    gitlab-runner unregister --url $URL --token $TOKEN $@
}

unregister_all(){
    local token
    for token in $(_get_registered_tokens); do
        TOKEN=$token
        unregister
    done
}

gitlab-runner register --executor $EXECUTOR -u $URL -r $TOKEN -n
/usr/bin/dumb-init /entrypoint run --user=gitlab-runner --working-directory=/home/gitlab-runner
