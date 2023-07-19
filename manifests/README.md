# CoreWeave-Megatron Development Manifests

This directory contains Kubernetes manifests and commands to set up a remote development environment
for running Megatron.

Using these, you may:

- Set up a Persistent Volume Claim (PVC) to hold testing datasets and modified versions of Megatron code
  for Kubernetes Pods to access
- Download testing datasets and clone repositories to the PVC
- Launch one-off training runs as Kubernetes *Jobs*
- Allocate a Kubernetes Pod as an SSH host to rapidly test changes with many single-node runs,
  or to debug interactively
    - This also allows easier access to deploy code updates onto the PVC.

## Preliminary Setup

> 🛈 These commands need only ever be run once, as prerequisites for launching later Pods.

### Persistent Volume Claim for Testing Data

First, set up a PVC (`megatron-pvc`) to house custom data for testing Megatron:

```bash
kubectl apply -f 00-megatron-pvc.yaml
```

### Download Testing Data

Then, start a Job to download an example dataset
[from here](https://huggingface.co/datasets/hakurei/megatron-dev-dataset)
and clone the CoreWeave Megatron fork to the PVC:

```bash
kubectl apply -f 01-dataset-download.yaml
```

### Usage

From here, continue to either the [One-Off Training Runs](#one-off-training-runs) or [SSH Pod](#ssh-pod) sections,
as appropriate.

## One-Off Training Runs

These manifests allow you to launch one-off training runs as Kubernetes *Jobs*.

> 🛈 Follow the instructions under [Preliminary Setup](#preliminary-setup) before continuing with this section.

### On a Single Node

Pre-train a 345M GPT model from scratch against the example dataset downloaded in the
[Download Testing Data](#download-testing-data) section by applying the following Kubernetes Job manifest:

```bash
kubectl apply -f single-node-trainer.yaml
```

Checkpoints are recorded in the PVC under the `checkpoints/` directory.

### On Multiple Nodes

> ⚠ Work in Progress

## SSH Pod

This section deploys an SSH server container that may be used for single-node interactive testing and development.

Notes:

- Only the `megatron-pvc` mount holds persistent data by default
- The entire configuration of the SSH server happens on pod startup in the deployment definition
    - This means starting up the server takes a minute longer, but does not require a base image customized for SSH use

> 🛈 Follow the instructions under [Preliminary Setup](#preliminary-setup) before continuing with this section.

To deploy the container, execute the following commands from this directory:

1. `kubectl apply -f 02-ssh-service.yaml`
    - Creates a Kubernetes Service to provide the IP address for connecting to the SSH Pod
2. `bash init-ssh-host-secret.sh`
    - Creates a Kubernetes Secret to deploy `ssh_host_ed25519_key` and `authorized_keys` files
3. `bash replace-ssh-authorized-keys.sh ~/.ssh/id_rsa.pub`
    - **Use a public key or pre-existing `authorized_keys` file of your choice here** in place of `~/.ssh/id_rsa.pub`
    - Configures the `root` user's `authorized_keys` file on Pod startup
    - Restart the Pod to apply changes to this setting
4. `kubectl apply -f ssh-node.yaml`
    - Launches the SSH Pod as a Kubernetes Deployment
5. `kubectl get service/megatron-ssh`
    - Shows the IP address for the SSH server
    - Use the value shown in the "`EXTERNAL-IP`" field to connect
6. `ssh root@X.X.X.X`
    - Connects to the node
    - Use the `EXTERNAL-IP` from the previous step in place of `X.X.X.X`

To shut down the SSH server, run `kubectl delete deployment/megatron-ssh`.
