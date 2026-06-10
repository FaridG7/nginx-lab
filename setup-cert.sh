#!/bin/bash
mkdir -p nginx/certs

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/certs/default.key \
  -out nginx/certs/default.crt \
  -subj "/CN=nginx-lab.local" \
  -addext "subjectAltName=DNS:nginx-lab.local,DNS:www.nginx-lab.local,DNS:localhost"
