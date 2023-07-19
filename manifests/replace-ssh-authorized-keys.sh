#!/bin/sh

kubectl get secret ssh-host-config -o json \
  | jq --arg authorized_keys "$(base64 -w0 < $1)" \
    '.data["authorized_keys"]=$authorized_keys' \
  | kubectl apply -f -;
