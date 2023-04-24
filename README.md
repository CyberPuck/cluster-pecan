# Cluster Pecan 🥧🥜 (No Pecan emoji 😿)

This is a configuration as code source for a kubernetes cluster.  It has the
code needed to setup a simple Raspberry Pi cluster for experimentation.

This will setup four individual nodes:

1. main-node (bridge from the Internet to the cluster network, DHCP)
2. node-1
3. node-2
4. node-3

## Setup Command Computer

The computer running these scripts needs to be configured.  Run the following:

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

- Raspberry Pi OS Lite (32-bit)
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

## Automated Setup

Running the `setup_cluster.py` script will auto-configure all nodes assigned to
the network.

### Main Node Setup

The main node needs the following packages:

- dnsmasq

The networking for `eth0` (physical Ethernet) needs to be configured for:

- 10.0.0.1/24 IP range
- dnsmasq needs to be setup for IP address handling
- IP tables need to be configured to allow Internet traffic into the cluster
- Generate hosts file for all nodes?
- Get kubernetes cluster configuration settings for all other nodes?

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
