# Cluster Pecan 🥧🥜 (No Pecan emoji 😿)

This is a configuration as code source for a kubernetes cluster. It has the
code needed to setup a simple Raspberry Pi cluster for experimentation.

This will setup four individual nodes:

1. main-node (bridge from the Internet to the cluster network, DHCP)
2. node-1
3. node-2
4. node-3

## Setup Command Computer

The computer running these scripts needs to be configured. Run the following:

### VirtualEnv Setup for Python

1. Setup venv: `./setup_venv.sh`
2. Start up venv for terminal session: `source ./venv/bin/activate`

### SSH Key Setup

On the computer that will be used to setup the Pis, create a SSH key:

```BASH
ssh-keygen -t ed25519 -C "Cluster SSH Key"
```

In the prompts use the following:
- Key name: `cluster_key`
- Password: <Use a tool like KeePass to generate the password>

### Setup Local SSH configuration

1. Restart venv if not running in shell: `source ./venv/bin/activate`
2. Run: `python3 setup_ssh.py`

## Required Hardware

This list can probably be expanded but for now has only been tested on Raspberry
Pis.

- 4 Raspberry Pis

## Required Software

Following software requirements:

### Raspberry Pi OS Setup

- On a computer connected to the Internet download the [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
Use this to install the following:

- Raspberry Pi OS Lite (64-bit)
- Press the Settings icon "⚙️", then fill in the following details:
1. Set the Hostname
1. Configured for SSH access, Check `Enable SSH`
    - Select `Allow public-key authentication only`
    - Copy the SSH public key contents into `Set authorized_keys for <user>`
1. Configure the username and password:
    - username: pi
    - password: <use a tool like KeePass to generate password>
1. **For main node** Setup Wi-Fi settings
    - SSID
    - Password
    - ***Set the country code!***
1. Other defaults are okay.
1. Press `SAVE`

## Network Access Through `main-node`

See [the wireguard role README for details](./playbooks/roles/wireguard/README.md).

## Automated Setup

Running the `setup_cluster.py` script will auto-configure all nodes assigned to
the network.

### Main Node Setup

Run the python script `./setup_main_node.py`.
This script will setup:

- docker
- kea dhcp service for delivering IP addresses
- networking (IP forwarding and net filter tables)
- wireguard (to access the cluster from an external network)

### All Nodes Setup

The following is needed on **all** nodes:

- kubeadm
- kubelet
- kubectl
- kubernetes-cni

These packages need the kubernetes.io registry added as a package registry to
install.

The following needs to be setup:

- Hostname lists added with IP addresses assigned (generated from `main-node`?)
- Kubernetes configured
- Nodes attached to cluster
