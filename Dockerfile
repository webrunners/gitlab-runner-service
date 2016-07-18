from gitlab/gitlab-runner:v1.3.3

ENV URL=CI-SERVER-URL
ENV TOKEN=CI-SERVER-TOKEN

# It could be shell
ENV EXECUTOR=RUNNER-EXECUTOR

ENTRYPOINT ["/bin/sh", "-c"]

CMD ["echo '%gitlab-runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/gitlab-runner; gitlab-runner register --executor $EXECUTOR -u $URL -r $TOKEN -n; /usr/bin/dumb-init /entrypoint run --user=gitlab-runner --working-directory=/home/gitlab-runner"]
