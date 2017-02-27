from gitlab/gitlab-runner:latest

ENV URL=CI-SERVER-URL
ENV TOKEN=CI-SERVER-TOKEN

# It could be shell
ENV EXECUTOR=RUNNER-EXECUTOR

RUN sudo -E apt-get install -yq --no-install-recommends curl ca-certificates\
 && [ ! -f /usr/bin/docker ] && (curl -sSL https://get.docker.com/ | sudo sh)\
 && [ ! -f /usr/local/bin/docker-compose ] && (curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` | sudo dd of=/usr/local/bin/docker-compose) || true\
 && [ ! -x /usr/local/bin/docker-compose ] && sudo chmod +x /usr/local/bin/docker-compose || true

COPY ./context/runner-init.sh /
RUN chmod a+x /runner-init.sh

ENTRYPOINT ["/usr/bin/dumb-init", "/runner-init.sh"]

CMD ["run", "--user=gitlab-runner", "--working-directory=/home/gitlab-runner"]
