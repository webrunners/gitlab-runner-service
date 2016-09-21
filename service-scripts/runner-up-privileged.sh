# 1=PROJECT, 2=TOKEN, 3=REPLICAS(2)
if [ ! $1 ] || [ ! $2 ]; then
 echo "Usage: $0 PROJECT TOKEN"
 exit
fi

PROJECT=$1
TOKEN=$2

# This container is not managed by swarm, because docker service still lacks some flags
# https://github.com/docker/docker/issues/24862

[[ ! $PROJECT == gitlab-runner-* ]] && PROJECT="gitlab-runner-$PROJECT"

docker run -d --restart always -v /var/run/docker.sock:/var/run/docker.sock --name $PROJECT -e "TOKEN=$TOKEN" -e "EXECUTOR=shell" -e "URL=https://code.webrunners.de:443/ci" webrunners/gitlab-runner-service


# curl -sSL https://get.docker.com/ | sh
