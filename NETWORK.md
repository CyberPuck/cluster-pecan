# Network

The networking is configured as a local network 10.0.0.0/24.  This means the
network devices that are assigned IP address from the DHCP service are from
10.0.0.2 - 10.0.0.254, 10.0.0.1 is assigned to the DHCP server and 10.0.0.255
is reserved for UDP multicast.

## Remote Access

Instructions online all talk of using the main-node as a jump host and once
SSHed into main-node, SSHing into the other resources from there.  A simpler
solution is going to be installing OpenVPN on main-node and then configuring
the Ansible controller to tunnel into the cluster network.

### OpenVPN Configuration

OpenVPN is configured with the following repo:
https://github.com/pivpn/pivpn

The current example is the following:
```BASH
curl -L https://install.pivpn.io | bash
```

This will install OpenVPN on `main-node` with the user `pi` having an OpenVPN
certificate generated for access to the network.

There might need to be considerations for the configuration.  The example
provided might not support headless/IaC installation.
