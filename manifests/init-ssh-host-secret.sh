#!/bin/bash

make-secret() {
  kubectl create secret generic ssh-host-config-1 --from-file=$1;
}

mkfifo ./ssh_host_ed25519_key_1 && \
  { { make-secret ./ssh_host_ed25519_key_1; rm ./ssh_host_ed25519_key_1; } & } && \
  { echo y | ssh-keygen -t ed25519 -N '' -q -f ./ssh_host_ed25519_key_1 > /dev/null; } || \
  rm ./ssh_host_ed25519_key_1;
