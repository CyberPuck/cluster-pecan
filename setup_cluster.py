# TODO: Some roles need to be tagged?
#   - main-node needs to be setup first with networking
# TODO: Setup NAT (including IPTABLES)
#   - This is a main-node task
# TODO: Setup pivpn for remote cluster access
#   - This is a main-node task
# TODO: Setup password-less SSH access
#   - Can we restrict SSH on the main-node to eth0, perhaps deny all incoming connections except `{{ vpn_port }}`?
#       - `iptables -A INPUT -i wlan0 -p tcp --dport 22 -j DROP`
#       - This will happen in  the second phase (to ensure we get the VPN setup first)
# TODO: Setup hostname files /etc/hostname
# TODO: Setup host files /etc/hosts
# TODO: Setup k8s cluster
#   - All nodes need:
#   1. k8s repo accepted
#   2. kubectl
#   3. kubeadm
#   4. kubelet
#   5. kubernetes-cni
