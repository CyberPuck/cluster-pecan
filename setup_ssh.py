# Simple Python script for setting up SSH configuration
import subprocess
import os

if __name__ == "__main__":
    print("PWD: ", os.getcwd())
    subprocess.run(['ansible-playbook', 'playbooks/setup_ssh.yaml'])
