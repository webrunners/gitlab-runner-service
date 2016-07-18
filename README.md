# gitlab-runner-service


### Install 

Copy the service-sripts to the leading node in /usr/local/bin and chmod a+x.


### Run

Default up scales to two replicas.

    ssh $node runner-up.sh PROJECT TOKEN REPLICAS(2)

### Scale

On scale-down the runners will be unregistered from GITLAB and removed.
Set _FACTOR_ to zero to remove all containers instead of deleting.

    ssh $node runner-scale.sh PROJECT FACTOR

### Check

    ssh $node docker service tasks gitlab-runner-$PROJECT

### Cleanup

For manual clean up GITLAB, you could use the gitlab API:

    for runner in {i..n}; do curl -X DELETE -H "PRIVATE-TOKEN: $TOKEN" "https://code.webrunners.de/api/v3/runners/$runner"; done
