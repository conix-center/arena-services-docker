#!/bin/bash

domains="$HOSTNAME $ADDITIONAL_HOSTNAMES" # space-separated list of domains
rsa_key_size=4096
email=$EMAIL # Adding a valid address is strongly recommended
staging_arg="" # Set to "--staging" if you're testing your setup to avoid hitting request limits

if [ -d "/etc/letsencrypt/live" ]; then
  read -p "Existing data found. Continue and replace existing letsencrypt files? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
  rm -fr /etc/letsencrypt/*
fi

echo "### Downloading recommended TLS parameters ..."
mkdir -p "/etc/letsencrypt"
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "/etc/letsencrypt/options-ssl-nginx.conf"
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "/etc/letsencrypt/ssl-dhparams.pem"

local="${HOSTNAME##*.}"
# if setting up a "localhost" or ".local" domain, just create a self-signed certificate
if [ $HOSTNAME = "localhost" ] || [ $local = "local" ]; then
  echo "### Creating self-signed certificate for $domains"
  path="/etc/letsencrypt/live/$domains"
  mkdir -p $path
  openssl req -x509 -nodes -newkey rsa:$rsa_key_size\
      -keyout "$path/privkey.pem" \
      -out "$path/fullchain.pem" \
      -subj "/CN=$domains"
  exit 0
fi

echo "### Requesting Let's Encrypt certificate for $domains ..."
# Join $domains to -d args
domain_args=""
for domain in ${domains}; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

certbot certonly --standalone -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos 
    
if [ $? -ne 0 ]
then
  echo
  echo "### !!! Could not create certificate. Certbot failed (see errors above) !!! ###"
  echo "### !!! Creating self-signed certificate for $domains !!! ###"
  path="/etc/letsencrypt/live/$domains"
  mkdir -p $path
  openssl req -x509 -nodes -newkey rsa:$rsa_key_size\
      -keyout "$path/privkey.pem" \
      -out "$path/fullchain.pem" \
      -subj "/CN=$domains"
  exit 0
fi
echo
