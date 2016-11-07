# gitlab-runner-service

### Define

    node=swarm-master-server

### Install 

    rsync -cvn --rsync-path="sudo rsync" service-scripts/*.sh $node:/usr/local/bin/
    ssh $node sudo chmod a+x /usr/local/bin/runner\*

or

    ansible-playbook -i inventory push.yml
    
### Create

Default up scales to one replica.

    ssh $node runner-up.sh PROJECT TOKEN REPLICAS(default: 1)

### Service tasks

On scale-down the runners will be unregistered from GITLAB and removed.
Set _FACTOR_ to zero to remove all containers instead of deleting.
    
    ssh $node docker service ls
    ssh $node docker service tasks NAME
    ssh $node docker service scale NAME=FACTOR
    ssh $node docker service update NAME
    ssh $node docker service rm NAME

### Privileged

It is now possible to create a privileged service. 
Remember: It hs full host root access

    docker service create --replicas=1 --name $PROJECT --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock -e "TOKEN=$TOKEN" -e "EXECUTOR=shell" -e "URL=https://code.webrunners.de:443/ci" webrunners/gitlab-runner-service

    ID=`ssh -q $node runner-up-privileged.sh PROJECT TOKEN REPLICAS(default: 1)`

### Privilged old

> This container is not managed by swarm, because docker service still lacks some flags
> https://github.com/docker/docker/issues/24862

    ID=`ssh -q $node runner-up-privileged.sh PROJECT TOKEN`

Get a shell

    ssh -t $node docker exec -it $ID bash
    su gitlab-runner
    sudo -Hu gitlab-runner

Get ID later

    ID=`ssh -q $node docker inspect --format="{{.Id}}" gitlab-runner-PROJECT`


Copy the ssh.key.pub shown in .gitlab-ci.yml build output of stage setup >> $target1:.ssh/authorized_keys 
    
    ssh $node docker exec -i $ID cat /home/gitlab-runner/.ssh/id_rsa.pub
    ssh -q $node docker exec -i $ID cat /home/gitlab-runner/.ssh/id_rsa.pub | ssh $target1 'cat >> /home/webrunners/.ssh/authorized_keys'
    ssh $target1 cat /home/webrunners/.ssh/authorized_keys

Test ssh and add fingerprint

    ssh -t $node docker exec -it $ID sudo -Hu gitlab-runner ssh $target1
    ssh -t $node docker exec -it $ID sudo -Hu gitlab-runner ssh $target2

Login to the docker registry

> Must not be done anymore as the gitlab-ci provides a login token on the fly.
> Only for reference

    ssh -t $node docker exec -it $ID sudo -Hu gitlab-runner docker login registry.webrunners.de
    ssh $node docker exec -i $ID cat /home/gitlab-runner/.docker/config.json

Remove the runner

    ssh $node docker kill $ID
    ssh $node docker rm $ID

Remove dangling volumes

> docker volume rm $(docker volume ls -qf dangling=true)

    ssh $node docker volume rm \$\(docker volume ls -qf dangling=true\)

Remove dangling images

> docker rmi $(docker images -qa -f 'dangling=true')

    ssh $node docker rmi \$\(docker images -qa -f 'dangling=true'\)

### Cleanup

For manual clean up GITLAB, you could use the gitlab API:

    for runner in {i..n}; do curl -X DELETE -H "PRIVATE-TOKEN: $TOKEN" "https://code.webrunners.de/api/v3/runners/$runner"; done

