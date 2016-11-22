# gitlab-runner-service


### Install 

    ansible-playbook -i inventory push.yml

### About

    run.sh is a local wrapper that just executes $@ on NODE
    so, when $1 == runner, runner.sh is executed

### Examples

    → ./run.sh -q runner -v -m up -n helo -r 4 -t mytoken -e docker
    docker service create --replicas 4 --name gitlab-runner-helo -e TOKEN=mytoken -e EXECUTOR=docker -e URL=https://code.webrunners.de:443/ci webrunners/gitlab-runner-service

    → ./run.sh docker -v
    NODE: dnet01.webrunners.de
    Docker version 1.12.3, build 6b644ec, experimental

    → ./run.sh docker service ls
    NODE: dnet01.webrunners.de
    ID            NAME                                       REPLICAS  IMAGE                             COMMAND
    xxx           gitlab-runner-name                         4/4       webrunners/gitlab-runner-service

    → ./run.sh -v -m container -n gitlab-runner-name
    NAME=gitlab-runner-name.1.xxxxxxxxxxxxxxxxxxx ID=xxxxxx NODE=dnet02 ./run.sh docker exec -it xxxxxx bash
    NODE: dnet02.webrunners.de
    ssh -qt dnet02.webrunners.de docker exec -it xxxxxx bash

### Usage

    Usage:
        /usr/local/bin/runner [options] [--][RAW]

    Options:
        -e  Executor    default: shell
        -h  This help
        -i  Image       default: webrunners/gitlab-runner-service
        -m  Mode        [raw|up|up-privileged|up-privileged-service]
        -n  Name
        -r  Replicas    default: 1
        -t  Token
        -v  Dry         Command output only
    RAW:
        Use doubledash if RAW starts with option
        Any RAW appends to command

### Scale service

On scale-down the runners will be unregistered from GITLAB and removed.
Set _FACTOR_ to zero to remove all containers instead of deleting.
Sometimes manual removing is still required. See cleanup below.

    ./run.sh docker service ls
    ./run.sh docker service ps NAME
    ./run.sh docker service scale NAME=FACTOR
    ./run.sh docker service update NAME
    ./run.sh docker service rm NAME

### Connect to some service container and prepare ssh

> https://github.com/docker/docker/issues/24862


Get all containers
    
    ./run.sh -m container -n gitlab-runner-name

Get a shell as gitlab-runner

    ./run.sh docker exec -it $CONTAINER bash
    su gitlab-runner
    sudo -Hu gitlab-runner

Copy the ssh.key.pub shown in .gitlab-ci.yml build output of stage setup >> $target:.ssh/authorized_keys 
    
    target=sub.dev.webrunners.de

    ./run.sh docker exec -i $ID cat /home/gitlab-runner/.ssh/id_rsa.pub | ssh $target 'tee -a /home/webrunners/.ssh/authorized_keys'
    ssh $target cat /home/webrunners/.ssh/authorized_keys

Test ssh and add fingerprint

    ./run.sh docker exec -it $ID sudo -Hu gitlab-runner ssh $target

Login to the docker registry

> Must not be done anymore as the gitlab-ci provides a login token on the fly.
> Only for reference

    ./run.sh docker exec -it $ID sudo -Hu gitlab-runner docker login registry.webrunners.de
    ./run.sh docker exec -i $ID cat /home/gitlab-runner/.docker/config.json

Remove the runner

    ./run.sh docker kill $ID
    ./run.sh docker rm $ID

Remove dangling volumes

> docker volume rm $(docker volume ls -qf dangling=true)

    ./run.sh docker volume rm \$\(docker volume ls -qf dangling=true\)

Remove dangling images

> docker rmi $(docker images -qa -f 'dangling=true')

    ./run.sh docker rmi \$\(docker images -qa -f 'dangling=true'\)

### Cleanup

For manual clean up GITLAB, you could use the gitlab API

    for runner in {i..n}; do curl -X DELETE -H "PRIVATE-TOKEN: $TOKEN" "https://code.webrunners.de/api/v3/runners/$runner"; done

#### Projectwise

 Get projects id

    curl -s -X GET -H "PRIVATE-TOKEN: $TOKEN" "https://code.webrunners.de/api/v3/projects?search=$NAME" | python3 -c "import sys, json; print(json.load(sys.stdin)[0]['id'])"  # 0 is the first result in array

 Get projects runners

    RUNNERS=$(curl -s -X GET -H "PRIVATE-TOKEN: $TOKEN" "https://code.webrunners.de/api/v3/projects/5/runners" | python3 -c "import sys, json; [print(r['id']) for r in json.load(sys.stdin)];")

 Delete them

    for runner in $RUNNERS; do curl -s -X DELETE -H "PRIVATE-TOKEN: $TOKEN" "https://code.webrunners.de/api/v3/runners/${runner[@]}"; done
