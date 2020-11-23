from alpine:latest

# install bash, compiler (build-base), python, envsubst (gettext), curl, wget, openssl, certbot and other dependencies
RUN apk add --update --no-cache bash build-base python3 python3-dev py3-pip libffi-dev gettext curl wget libressl-dev openssl openssl-dev musl-dev libffi-dev && \
    rm -rf /var/cache/apk/*

RUN ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools
RUN pip3 install certbot-nginx

RUN mkdir /utils
WORKDIR /utils

COPY . .
RUN pip3 install -r /utils/requirements.txt

