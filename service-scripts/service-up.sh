
if [ ! $1 ] || [ ! $2 ]; then
 echo "Usage: $0 NAME REPLICAS \$@(docker service create options)"
 exit
fi

NAME=$1
REPLICAS=$2
shift 2

docker service create --replicas $REPLICAS --name $NAME $@
