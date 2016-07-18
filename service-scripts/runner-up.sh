# 1=PROJECT, 2=TOKEN, 3=REPLICAS(2)
if [ ! $1 ] || [ ! $2 ]; then
 echo "Usage: $0 PROJECT TOKEN REPLICAS(default: 2)"
 exit
fi

PROJECT=$1
TOKEN=$2
REPLICAS=${3:-2}

docker service create --replicas $REPLICAS --name gitlab-runner-$PROJECT -e "TOKEN=$TOKEN" -e "EXECUTOR=shell" -e "URL=https://code.webrunners.de:443/ci" webrunners/gitlab-runner-service
