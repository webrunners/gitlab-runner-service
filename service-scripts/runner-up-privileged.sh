# 1=PROJECT, 2=TOKEN, 3=REPLICAS(2)
if [ ! $1 ] || [ ! $2 ]; then
 echo "Usage: $0 PROJECT TOKEN REPLICAS(default: 1)"
 exit
fi

PROJECT=$1
TOKEN=$2
REPLICAS=1

shift 2
if [[ $1 ]]; then
    REPLICAS=$1
    shift
fi

[[ ! $PROJECT == gitlab-runner-* ]] && PROJECT="gitlab-runner-$PROJECT"

docker service create --replicas=$REPLICAS --name $PROJECT --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock -e "TOKEN=$TOKEN" -e "EXECUTOR=shell" -e "URL=https://code.webrunners.de:443/ci" $@ webrunners/gitlab-runner-service

# curl -sSL https://get.docker.com/ | sh
