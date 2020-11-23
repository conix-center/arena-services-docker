# Init utils
Init scripts dependencies. All init scripts dependencies (bash, compiler (build-base), python, envsubst (gettext), curl, wget, openssl, certbot, ...) are put into this docker container, so that all we need is docker.

To build and push the container to docker hub (you will need dockerhub credentials to push):
```./build-push-container.sh```
