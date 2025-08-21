# Network

The networking is configured as a local network 10.0.0.0/24. This means the
network devices that are assigned IP address from the DHCP service are from
10.0.0.2 - 10.0.0.254, 10.0.0.1 is assigned to the DHCP server and 10.0.0.255
is reserved for UDP multicast.

## Remote Access

Remove access is through WireGuard running on the router. This will give full
network access to the cluster, from there kubectl, kubeadm, k9s, or ssh can be
leveraged.

