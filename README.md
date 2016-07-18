# gitlab-runner-service


### Install 

    rsync -av --rsync-path="sudo rsync" service-scripts/*.sh $node:/usr/local/bin/

### Create

Default up scales to two replicas.

    ssh $node runner-up.sh PROJECT TOKEN REPLICAS(default: 2)

### Other tasks

On scale-down the runners will be unregistered from GITLAB and removed.
Set _FACTOR_ to zero to remove all containers instead of deleting.
    
    ssh $node docker service ls
    ssh $node docker service tasks NAME
    ssh $node docker service scale NAME=FACTOR
    ssh $node docker service update NAME
    ssh $node docker service rm NAME

### Cleanup

For manual clean up GITLAB, you could use the gitlab API:

    for runner in {i..n}; do curl -X DELETE -H "PRIVATE-TOKEN: $TOKEN" "https://code.webrunners.de/api/v3/runners/$runner"; done

