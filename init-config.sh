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

echo -e "\n### Creating RSA key pair (conf/keys/pubsubkey.pem). This will replace old keys (if exist; backup will be in data/keys/pubsubkeyspem.bak)."
read -p "Create RSA key pair ? (y/N) " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  openssl genrsa -out ./data/keys/pubsubkey.pem 4096
  openssl rsa -in ./data/keys/pubsubkey.pem -RSAPublicKey_out -outform pem -out ./data/keys/pubsubkey.pub
  openssl rsa -in ./data/keys/pubsubkey.pem -RSAPublicKey_out -outform DER -out ./data/keys/pubsubkey.der
  # generate service tokens
  grep -v '^SERVICE_' secret.env > secret.tmp # remove all service tokens
  cp secret.tmp secret.env
  services=( "arena_persist" "arena_arts" )
  for s in "${services[@]}"
  do
    tn="SERVICE_${s^^}_JWT"
    echo "$tn=$(python /utils/genjwt.py -k ./data/keys/pubsubkey.pem $s)" >> secret.env
  done
fi

# load secrets 
export $(grep -v '^#' secret.env | xargs)

echo -e "\n### Contents of .env:\n"
cat .env
echo

echo -e "Please edit the file .env (shown above) to reflect your setup (hostname, email, ...). \n"
read -p "Continue? (y/N)" -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Stopped."
    exit 0
fi

# setup escape var for envsubst templates
export ESC="$"

echo -e "\n### Creating config files (conf/*) from templates (conf-templates/*)"
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

# copy public key
[ -f "./data/keys/pubsubkey.pub" ] && cp ./data/keys/pubsubkey.pub ./conf/arena-web-conf/ 
