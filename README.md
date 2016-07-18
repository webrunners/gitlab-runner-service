# gitlab-runner-service


For manual cleaning up, you could use the gitlab API:

    for runner in {i..n}; do curl -X DELETE -H "PRIVATE-TOKEN: $TOKEN" "https://code.webrunners.de/api/v3/runners/$runner"; done
