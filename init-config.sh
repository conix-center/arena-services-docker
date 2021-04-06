#!/bin/bash

echo -e "\n### Creating data folders\n"
data_folders=( "data/arena-store" "data/grafana"  "data/mongodb"  "data/prometheus" "data/account" "data/keys")
[ ! -d "data" ] && mkdir data
for d in "${data_folders[@]}"
do
  echo $d
  [ ! -d "$d" ] && mkdir $d && chown $OWNER $d
done

[ ! -d conf ] && mkdir conf && chown $OWNER conf

echo -e "\n### Creating secret.env (with secret keys, admin password). This will replace old secret.env (if exists; backup will be in secret.env.bak)."
read -p "Create secret.env ? (y/N) " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  SECRET_KEY=$(LC_ALL=C tr -dc '[:alnum:]' < /dev/urandom | head -c40)
  SECRET_KEY_BASE64=$(echo $SECRET_KEY | base64)
  cp secret.env secret.env.bak
  echo "SECRET_KEY=$SECRET_KEY" > secret.env
  echo "SECRET_KEY_BASE64=$SECRET_KEY_BASE64" >> secret.env
  echo "DJANGO_SUPERUSER_PASSWORD=$(LC_ALL=C tr -dc '[:alnum:]' < /dev/urandom | head -c15)" >> secret.env

  chown $OWNER secret.env # change ownership of file created
fi

echo -e "\n### Creating RSA key pair for JWT (conf/keys/jwt.priv.pem). This will replace old keys (if exist; backup will be in data/keys/jwt.priv.pem.bak)."
read -p "Create RSA key pair ? (y/N) " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  [ -f ./data/keys/jwt.priv.pem ] && cp ./data/keys/jwt.priv.pem data/keys/jwt.priv.pem.bak
  rm ./data/keys/*
  openssl genrsa -out ./data/keys/jwt.priv.pem 4096
  openssl rsa -in ./data/keys/jwt.priv.pem -pubout -outform PEM -out ./data/keys/jwt.public.pem
  openssl rsa -in ./data/keys/jwt.priv.pem -RSAPublicKey_out -outform DER -out ./data/keys/jwt.public.der # mqtt auth plugin requires RSAPublicKey format
  # change ownership public keys
  chown $OWNER ./data/keys/jwt.public*
fi

rm ./conf/arena-web-conf/*.pem
# copy public key to /conf/sha256(hostname).pem to be used for Atlassian Service Authentication Protocol (ASAP)
HOSTSHA256=$(echo -n $HOSTNAME | shasum -a 256)
cat ./data/keys/jwt.public.pem > ./conf/arena-web-conf/${HOSTSHA256%???}.pem

echo -e "\n### Creating Service Tokens. This will replace service tokens in secret.env (if exists; backup will be in secret.env.bak)."
read -p "Create Service Tokens ? (y/N) " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  grep -v '^SERVICE_' secret.env > secret.tmp # remove all service tokens
  cp secret.env secret.env.bak
  cp secret.tmp secret.env
  services=( "arena_persist" "arena_arts" "py_runtime" "mqttbr")
  for s in "${services[@]}"
  do
    tn="SERVICE_${s^^}_JWT"
    echo "$tn=$(python /utils/genjwt.py -k ./data/keys/jwt.priv.pem $s)" >> secret.env
  done
fi

# load secrets 
export $(grep -v '^#' secret.env | xargs)

echo -e "\n### Creating config files (conf/*) from templates (conf-templates/*) and .env"
echo -e "\n\nContents of .env:\n"
cat .env
echo

echo -e "Please edit the file .env (shown above) to reflect your setup (hostname, email, ...). \n"
read -p "Continue and create config files (backups will be created in conf/)? (y/N)" -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Stopped."
    exit 0
fi

# setup escape var for envsubst templates
export ESC="$"

# create a list of hostnames for python config files
HOSTNAMES_LIST=""
for host in $(echo "$HOSTNAME $ADDITIONAL_HOSTNAMES"|tr ' ' '\n'); do
  HOSTNAMES_LIST="$HOSTNAMES_LIST '$host',"
done
export HOSTNAMES_LIST=${HOSTNAMES_LIST::-1} # remove last comma

for t in $(find conf-templates/ -type f)
do
  t="${t:15}" # remove "conf-templates/"
  f="${t%.*}" # remove trailing ".tmpl"
  d="$(dirname $f)" # get folder inside conf-templates 
  if [[ ! $d = "." ]]; then 
    [ ! -d "conf/$d" ] && mkdir "conf/$d" && chown $OWNER "conf/$d" # create destinatinon folder if needed
  fi
  cp conf/$f conf/$f.bak >/dev/null 2>&1
  echo -e "\t conf-templates/$t -> conf/$f"
  envsubst < conf-templates/$t > conf/$f
  chown $OWNER conf/$f
done

# add server block to redirect additional hostnames
if [[ ! -z "$ADDITIONAL_HOSTNAMES" ]]; then
        TMPFN=/tmp/nginx_tmpcfg
        cat > $TMPFN <<  EOF

server {
    server_name         $ADDITIONAL_HOSTNAMES;
    server_tokens off;
    client_max_body_size 1000M;

    listen              443 ssl;
    ssl_certificate     /etc/letsencrypt/live/arenaxr.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/arenaxr.org/privkey.pem;
    include             /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;

    location ^~ /user/ {
        add_header 'Access-Control-Allow-Origin' "$http_origin";
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS, DELETE, PUT';
        add_header 'Access-Control-Allow-Credentials' 'true';
        add_header 'Access-Control-Allow-Headers' 'User-Agent,Keep-Alive,Content-Type';
        proxy_pass http://arena-account:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_read_timeout 86400;
    }

    location / {
        return 301 https://$HOSTNAME$request_uri;
    }
}
EOF
        # add server block to production and staging
        cat $TMPFN >> ./conf/arena-web.conf
        cat $TMPFN >> ./conf/arena-web-staging.conf
        rm $TMPFN
fi

# add server block to redirect jitsi requests
if [[ ! -z "$JITSI_HOSTNAME" ]]; then
    echo -e "\n### If you are going to setup a Jitsi server on this machine, you will configure nginx to redirect http requests to a Jitsi virtual host (JITSI_HOSTNAME is an alias to the IP of the machine)."
    read -p "Add server block to redirect requests to Jitsi ? (y/N) " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        TMPFN=/tmp/nginx_tmpcfg
        JITSI_HOSTNAME_NOPORT=$(echo $JITSI_HOSTNAME | cut -f1 -d":")
        cat > $TMPFN <<  EOF

server {
    server_name         $JITSI_HOSTNAME_NOPORT;
    listen              80;
    location /.well-known/acme-challenge/ {  
        proxy_pass http://$JITSI_HOSTNAME_NOPORT:8000;
    }    
    location / {  
        return 301 https://$JITSI_HOSTNAME$request_uri;
    }    
}
EOF
        # add server block to production and staging
        cat $TMPFN >> ./conf/arena-web.conf
        cat $TMPFN >> ./conf/arena-web-staging.conf
        rm $TMPFN
    fi
fi 
