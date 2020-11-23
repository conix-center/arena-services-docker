#!/usr/bin/env python3

import argparse
from datetime import datetime, timedelta
import jwt


def generate_token(username, keypath):
    now = datetime.utcnow()
    claim = {
        "sub": username,
        "subs": ["#"],
        "publ": ["#"],
        'iat': now,
        'exp': now + timedelta(days=365)
    }
    with open(keypath, 'r') as keyfile:
        key = keyfile.read()
    token = jwt.encode(claim, key, algorithm='RS256')
    print(token.decode())


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=(
        "Generate JWT service tokens w/ pub/sub rights to all topics and 1 year expiry"))
    parser.add_argument('username', help='MQTT username for this service')
    parser.add_argument('-k', dest='keypath', default="mqtt.pem",
                        help='Private RSA key file to use (default "mqtt.pem")')
    args = parser.parse_args()
    generate_token(args.username, args.keypath)
