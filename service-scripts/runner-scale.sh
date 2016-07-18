# 1=project, 2=FACTOR
if [ ! $1 ] || [ ! $2 ]; then
 echo "Usage: $0 PROJECT FACTOR"
 exit
fi
docker service scale gitlab-runner-$1=$2
