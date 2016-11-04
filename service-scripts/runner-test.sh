# 1=TOKEN 2=IMAGE
if [ ! $1 ]; then
 echo "Usage: $0 TOKEN IMAGE(default: webrunners/gitlab-runner-service) SERVICE(default: -ti --rm)"
 exit
fi

SERVICE=${3:=-ti --rm}
IMAGE=${2:=webrunners/gitlab-runner-service}

docker run $SERVICE -e "TOKEN=$1" -e "EXECUTOR=shell" -e "URL=https://code.webrunners.de:443/ci" $IMAGE
