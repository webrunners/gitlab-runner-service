# 1=project, 2=TOKEN, 3=replicas(2)
if [ ! $1 ] || [ ! $2 ]; then
 echo "Usage: $0 PROJECT FACTOR REPLICAS(2)"
 exit
fi
docker service create --replicas ${3:-2} --name gitlab-runner-$1 -e "TOKEN=$2" -e "EXECUTOR=shell" -e "URL=https://code.webrunners.de:443/ci" webrunners/gitlab-runner-service
