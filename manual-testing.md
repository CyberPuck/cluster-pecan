# Cluster Manual Setup

## Current OS deployments 2024-02-26

|Device|OS|Debian Version|
|------|--|--------------|
|RPi 1|Bullseye|11|
|RPi 2|Bullseye|11|
|RPi 3|Bullseye|11|
|RPi 4|Bookworm|12|
|RPi 5|Bookworm|12|

## main-node

Basics:
- `sudo apt-get install vim`
- `sudo apt-get update`
- `sudo apt-get upgrade`
- `sudo apt-get dist-upgrade`

Installing:
1. unattended-upgrades
2. apt-listchanges

`sudo apt-get install unattended-upgrades apt-listchanges`

### unattended-upgrades

#### Setup Packages and Email Alert

`vim /etc/apt/apt.conf.d/50unattended-upgrades`

#### Activate Setup

`vim /etc/apt/apt.conf.d/20auto-upgrades`
`vim /etc/apt/apt.conf.d/02periodic`

### Networking

- Setup `dhcpcd` to ignore eth0
    - Edit `/etc/dhcpcd.conf` and add `denyinterfaces eth0`
    - I'm assuming there is some connection with `wlan0` still?
- Reboot Pi `sudo reboot`

**NOTE: May differ with new OS releases**
- Created `eth0` setup at `/etc/network/interfaces.d/eth0`

```txt
allow-hotplug eth0
iface eth0 inet static
    address 10.0.0.1
    netmask 255.255.255.0
    broadcast 10.0.0.255
    gateway 10.0.0.1
```

- Reboot the Pi `sudo reboot`

#### Installed DHCP Server

##### ISC-DHCP-SERVER EOL Setup

`sudo apt-get install isc-dhcp-server`

Setup `/etc/dhcp/dhcpd.conf`

```
# dhcpd.conf
#
# Cluster Config
#

# Option for default network
option domain-name "cluster.home";
option domain-name-servers 1.1.1.1, 9.9.9.9;

subnet 10.0.0.0 netmask 255.255.255.0 {
    range 10.0.0.1 10.0.0.10;
    option subnet-mask 255.255.255.0;
    option broadcast-address 10.0.0.255;
    option routers 10.0.0.1;
}

default-lease-time 600;
max-lease-time 7200;
authoritative;
```

- Restart dhcp service `sudo systemctl restart isc-dhcp-server`
- **NOTE:** ISC DHCP Server Service is reporting errors... but handing out IPs?
    - Maybe it is working but is unhappy with modern Raspberry Pi configs?
    - Add `sudo vim /etc/default/isc-dhcp-server` `eth0` to IPv4 interfaces

##### isc-kea-dhcp4-server setup

`sudo apt-get install isc-kea-dhcp4-server`

Setup config at `/etc/kea/kea-dhcp4.conf`

```json
// Basic setup
{
    "Dhcp4": {
        "interface-config": {
            "interfaces": [ "eth0" ]
        },
        "control-socket": {
            "socket-type": "unix",
            "socket-name": "/run/kea/kea4-ctrl-socket"
        },
        "lease-database": {
            "type": "memfile",
            "lfc-interval": 3600
        },
        "valid-lifetime": 600,
        "max-valid-lifetime": 7200,
        "subnet4": [
            {
                "id": 1,
                "subnet": "10.0.0.0/24",
                "pools": [
                    {
                        "pool": "10.0.0.1 - 10.0.0.20"
                    }
                ],
                "option-data": [
                    {
                        "name": "routers",
                        "data": "10.0.0.1"
                    },
                    {
                        "name": "domain-name-servers",
                        "data": "1.1.1.1, 9.9.9.9"
                    },
                    {
                        "name": "domain-name",
                        "data": "cluster.home"
                    }
                ]
            }
        ]
    }
}
```

#### Setup IP Forwarding

- Edit `/etc/sysctl.conf`, enable `net.ipv4.ip_forward=1`
- Reboot **or** run `sudo sysctl net.ipv4.ip_forward=1`

#### NFT Setup

- Require following:
1. Bridge from eth0 to wlan0
2. Masquer traffic from wlan0 to eth0
3. We need to probably setup VPN route from wlan0 to eth0 (stretch goal)

##### Full Setup

**NOTE:** These are the old rules getting translated... they didn't work:

- `sudo nft add table nat`
- `sudo nft add chain nat postrouting`
- `sudo nft add rule ip nat postrouting oifname "wlan0" counter masquerade`
- `sudo nft add table filter`
- `sudo nft add chain filter forward`
- `sudo nft add rule ip filter forward iifname "wlan0" oifname "eth0" ct state related,established  counter accept`
- `sudo nft add rule ip filter forward iifname "eth0" oifname "wlan0" counter accept`

According to [RedHat](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/security_guide/sec-configuring_nat_using_nftables)
this is how to configure NAT Masquerade (section 6.3.2 Configuring masquerding using nftables):
```bash
sudo nft add table nat
sudo nft -- add chain nat prerouting { type nat hook prerouting priority -100 \; }
sudo nft add chain nat postrouting { type nat hook postrouting priority 100 \; }
sudo nft add rule nat postrouting oifname "wlan0" masquerade
```

We need to verify the rule set `sudo nft list ruleset`

```text
table ip nat {
    chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
    }

    chain postrouting {
        type nat hook postrouting priority srcnat; policy accept;
        oifname "wlan0" masquerade
    }
}
```

- Copy the ruleset to the end of `/etc/nftables.conf`
    - Should we remove the old ruleset?
- Enable nft `sudo systemctl enable nftables`
- Start nft `sudo systemctl start nftables`


## Current Errors

```
failed: [main-node] (item=/srv/kea) => {"ansible_loop_var": "item", "changed": false, "item": "/srv/kea", "msg": "There was an issue creating /srv/kea as requested: [Errno 13] Permission denied: b'/srv/kea'", "path": "/srv/kea"}
failed: [main-node] (item=/srv/kea/config) => {"ansible_loop_var": "item", "changed": false, "item": "/srv/kea/config", "msg": "There was an issue creating /srv/kea as requested: [Errno 13] Permission denied: b'/srv/kea'", "path": "/srv/kea/config"}
failed: [main-node] (item=/srv/kea/leases) => {"ansible_loop_var": "item", "changed": false, "item": "/srv/kea/leases", "msg": "There was an issue creating /srv/kea as requested: [Errno 13] Permission denied: b'/srv/kea'", "path": "/srv/kea/leases"}
failed: [main-node] (item=/srv/kea/logs) => {"ansible_loop_var": "item", "changed": false, "item": "/srv/kea/logs", "msg": "There was an issue creating /srv/kea as requested: [Errno 13] Permission denied: b'/srv/kea'", "path": "/srv/kea/logs"}
failed: [main-node] (item=/srv/kea/sockets) => {"ansible_loop_var": "item", "changed": false, "item": "/srv/kea/sockets", "msg": "There was an issue creating /srv/kea as requested: [Errno 13] Permission denied: b'/srv/kea'", "path": "/srv/kea/sockets"}
failed: [main-node] (item=/srv/kea/entrypoint.d) => {"ansible_loop_var": "item", "changed": false, "item": "/srv/kea/entrypoint.d", "msg": "There was an issue creating /srv/kea as requested: [Errno 13] Permission denied: b'/srv/kea'", "path": "/srv/kea/entrypoint.d"}
```

# TODO

0. ISC-DHCP-SERVER is EOL as of 2022! Switch to isc-kea-dhcp4-server
    - Fat fucking chance on that, can't build on RPi 3
    - Built on RPi 4 with `aarch64` OS, need to rebuild main
    - Updates to main has induced nft rule error? Maybe not?
    - Missing lib files from kea build, will need to tar up and move files around
0. Network appears slow, is this a hardware issue? Upgrade primary node to RPi4/5?
1. Setup NFT Rules
    - Needed to enable and start nftables, ruleset now being applied on reboot
    - Needed to follow RedHat instructions
    - **NOTE:** These rules may fully open the cluster, might need to strengthen perimeter
2. Setup hostnames?
    - 
3. Setup Kubernetes