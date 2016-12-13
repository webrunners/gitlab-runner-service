# gitlab-runner-service

## About

    Helper scripts for swarm mode service creation using an customized gitlab-runner Docker image.

## Helper scripts

### runner.sh

    runner.sh is installed as command `runner` on the swarm-master.
    It wraps commands for docker service creation

#### Install

    cd deploy
    ansible-playbook -i inventory deploy.yml

### manage/swarm.sh

    manage/swarm.sh is a local command that just executes commands on NODE.
    When mode=runner, runner.sh is executed on the swarm-master.
    
    Set environment variable NODE on the commandline or in the file `.conf`

### Usage manage/swarm.sh

    Usage:
        ./manage/swarm.sh [options] [--][RAW]

    Options:
        -q  Quiet       Suppress informational output
        -m  Mode        default: ssh [list-containers|list-services|runner|ssh]
        -n  Name        The name of the service to manage
        -v  Dry         Command output only

    RAW:
        Use the doubledash -- if RAW starts with option.
        For mode=runner you have to use the -- before any runner options.

### Usage runner.sh

    Usage:
        /usr/local/bin/runner [options] [--][RAW]

    Options:
        -e  Executor    default: shell
        -h  This help
        -i  Image       default: webrunners/gitlab-runner-service
        -m  Mode        [create|up|up-privileged|up-privileged-service]
        -n  Name
        -r  Replicas    default: 1
        -t  Token
        -v  Dry         Command output only
    RAW:
        Use doubledash if RAW starts with option
        Any RAW appends to command


### Examples

    → ./manage/swarm.sh -q -m runner -- -v -m up -n helo -r 4 -t mytoken -e docker

    # the same but through mode=ssh which is default
    → ./manage/swarm.sh -q runner -v -m up -n helo -r 4 -t mytoken -e docker
    
    → ./manage/swarm.sh -q runner -vm create
    
    → ./manage/swarm.sh -m ssh docker -v

    → ./manage/swarm.sh -m ssh docker service ls

    → ./manage/swarm.sh -m list-containers -n gitlab-runner-name


### Scale service

On scale-down the runners will be unregistered from GITLAB and removed.
Set _FACTOR_ to zero to remove all containers instead of deleting.
Sometimes manual removing is still required. See cleanup below.

    ./manage/swarm.sh -m ssh docker service ls
    ./manage/swarm.sh -m ssh docker service ps NAME
    ./manage/swarm.sh -m ssh docker service scale NAME=FACTOR
    ./manage/swarm.sh -m ssh docker service update NAME
    ./manage/swarm.sh -m ssh docker service rm NAME

## Cleanup

Remove specific container

    ./manage/swarm.sh -m ssh docker kill $ID
    ./manage/swarm.sh -m ssh docker rm $ID

Remove dangling volumes

> docker volume rm $(docker volume ls -qf dangling=true)

    ./manage/swarm.sh -m ssh docker volume rm \$\(docker volume ls -qf dangling=true\)

Remove dangling images

> docker rmi $(docker images -qa -f 'dangling=true')

    ./manage/swarm.sh -m ssh docker rmi \$\(docker images -qa -f 'dangling=true'\)

### GitLab API

For manual clean up GITLAB runners, you could use the gitlab API

    TOKEN=GitLab-Token
    GITLAB=GitLab-Url

#### By ascending id

    for runner in {i..n}; do curl -X DELETE -H "PRIVATE-TOKEN: $TOKEN" "https://$GITLAB/api/v3/runners/$runner"; done

#### Projectwise

 Get projects id

    ID=`curl -s -X GET -H "PRIVATE-TOKEN: $TOKEN" "https://$GITLAB/api/v3/projects?search=$NAME" | python3 -c "import sys, json; print(json.load(sys.stdin)[0]['id'])"`  # 0 is the first search result in array

 Get projects runners

    RUNNERS=($(curl -s -X GET -H "PRIVATE-TOKEN: $TOKEN" "https://$GITLAB/api/v3/projects/$ID/runners" | python3 -c "import sys, json; [print(r['id']) for r in json.load(sys.stdin)];"))

 Get description

    for runner in ${RUNNERS[@]}; do curl -s -X GET -H "PRIVATE-TOKEN: $TOKEN" "https://$GITLAB/api/v3/runners/$runner"|python3 -c "import sys, json; print(json.load(sys.stdin)['description'])"; done

 Delete them

    for runner in ${RUNNERS[@]}; do curl -s -X DELETE -H "PRIVATE-TOKEN: $TOKEN" "https://$GITLAB/api/v3/runners/$runner"; done


## Connect to some service container and prepare ssh

> Deprecated
> improved .gitlab-ci.yml

Get all containers
    
    ./manage/swarm.sh -m list-containers -n gitlab-runner-name

Get a shell as gitlab-runner

    ./manage/swarm.sh docker exec -it $CONTAINER bash
    su gitlab-runner
    sudo -Hu gitlab-runner

Copy the ssh.key.pub shown in .gitlab-ci.yml build output of stage setup >> $target:.ssh/authorized_keys 
    
    TARGET=sub.dev.webrunners.de
    ID=container_id

    ./manage/swarm.sh -m ssh docker exec -i $ID cat /home/gitlab-runner/.ssh/id_rsa.pub | ssh $TARGET 'tee -a /home/webrunners/.ssh/authorized_keys'
    ssh $TARGET cat /home/webrunners/.ssh/authorized_keys

Test ssh and add fingerprint

    ./manage/swarm.sh -m ssh docker exec -it $ID sudo -Hu gitlab-runner ssh $TARGET

Login to the docker registry

> Deprcated
> Has not to be done anymore as the gitlab-ci provides a login token on the fly.
> Only for reference

    ./manage/swarm.sh docker exec -it $ID sudo -Hu gitlab-runner docker login registry.webrunners.de
    ./manage/swarm.sh docker exec -i $ID cat /home/gitlab-runner/.docker/config.json

## Follow ups

> https://github.com/docker/docker/issues/24862
