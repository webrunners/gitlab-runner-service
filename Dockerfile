from gitlab/gitlab-runner:v1.3.3

ENV URL=CI-SERVER-URL
ENV TOKEN=CI-SERVER-TOKEN

# It could be shell
ENV EXECUTOR=RUNNER-EXECUTOR

COPY runner-init.sh /
RUN chmod a+x runner-init.sh

ENTRYPOINT []

CMD ["/runner-init.sh"]
