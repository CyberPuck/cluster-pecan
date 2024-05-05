# Runs the initial setup of the main-node server.
# This includes the following:
# 1. Base networking (IP forwarding, IPTABLES, eth0 static IP)
# 2. DHCP - through dnsmasq
# 3. VPN - pivpn

import subprocess
import os

if __name__ == "__main__":
    print("PWD: ", os.getcwd())
    subprocess.run(['ansible-playbook', 'playbooks/setup_main_node.yml', '-i', 'inventory.yaml'])
