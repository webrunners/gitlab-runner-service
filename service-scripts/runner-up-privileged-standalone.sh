# 1=PROJECT, 2=TOKEN, 3=REPLICAS(2)
if [ ! $1 ] || [ ! $2 ]; then
 echo "Usage: $0 PROJECT TOKEN IMAGE(default: webrunners/gitlab-runner-service:latest)"
 exit
fi

PROJECT=$1
TOKEN=$2
IMAGE=${3:=webrunners/gitlab-runner-service}

shift 2
[[ $3 ]] && shift

[[ ! $PROJECT == gitlab-runner-* ]] && PROJECT="gitlab-runner-$PROJECT"

docker run -d --restart always -v /var/run/docker.sock:/var/run/docker.sock --name $PROJECT -e "TOKEN=$TOKEN" -e "EXECUTOR=shell" -e "URL=https://code.webrunners.de:443/ci" $IMAGE