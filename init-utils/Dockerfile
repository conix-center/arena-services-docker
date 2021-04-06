from alpine:latest

# install bash, compiler (build-base), python, envsubst (gettext), curl, wget, openssl, git, node and other dependencies
RUN apk add --update --no-cache bash build-base python3 python3-dev py3-pip libffi-dev gettext curl wget libressl-dev openssl openssl-dev git nodejs npm musl-dev libffi-dev musl-dev cargo perl-utils && \
    rm -rf /var/cache/apk/*

RUN ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip install --no-cache --upgrade pip setuptools wheel
RUN pip install certbot-nginx

RUN mkdir /utils
WORKDIR /utils

COPY . .
RUN pip install -r /utils/requirements.txt

