# Setup the kubernetes cluster, uses inventory to reach all resources

import subprocess
import os

if __name__ == "__main__":
    print("PWD: ", os.getcwd())
    subprocess.run(['ansible-playbook', 'playbooks/setup_cluster.yml', '-i', 'inventory.yaml', '--timeout', '60'])
