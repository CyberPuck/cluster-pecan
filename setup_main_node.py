# Runs the initial setup of the main-node server.

import subprocess
import os

if __name__ == "__main__":
    print("PWD: ", os.getcwd())
    subprocess.run(['ansible-playbook', 'playbooks/setup_main_node.yml', '-i', 'inventory.yaml'])
