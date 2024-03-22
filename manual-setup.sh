#!/bin/sh

# Setup main-node for RPi
# Tired of constantly reflashing and typing in commands
# Instructions are **5** years old! 🤢

echo "Installing updates/upgrades..." >> install.log
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get autoclean -y
sudo apt-get autoremove -y
echo "Installing utils..." >> install.log
sudo apt-get install vim git -y >> install.log
echo "Installing unatteneded-upgrades..." >> install.log
sudo apt-get install unattended-upgrades -y >> install.log
# There is no ARM version?
#echo "Installing kea-dhcp4..." >> install.log
#curl -1sLf 'https://dl.cloudsmith.io/public/isc/kea-2-4/setup.deb.sh' | sudo -E bash
#sudo apt-get install isc-kea-dhcp4-server -y >> install.log

# kea build env - requires a RPi 4 or newer 😤
echo "Installing kea build environment..." >> install.log
sudo apt-get install automake libtool pkg-config build-essential ccache -y
sudo apt-get install libboost-dev libboost-system-dev liblog4cplus-dev libssl-dev -y

# Setup signing key, following instructions here: https://www.isc.org/pgpkey/
echo "Setting up ISC code signing key..." >> install.log
wget https://www.isc.org/docs/isc-keyblock.asc
gpg --import isc-keyblock.asc

# verify and download tarball
echo "Getting and verifying tarball..." >> install.log
wget https://ftp.isc.org/isc/kea/2.4.1/kea-2.4.1.tar.gz.asc
wget https://ftp.isc.org/isc/kea/2.4.1/kea-2.4.1.tar.gz
gpg --verify kea-2.4.1.tar.gz.asc kea-2.4.1.tar.gz

# Build software: https://kb.isc.org/v1/docs/kea-build-on-debian
echo "Building kea..." >> install.log
tar xvfz kea-2.4.1.tar.gz
cd kea-2.4.1
# These are missing in RPi OS 😮‍💨
# Im assuming these are nice to haves? Maybe RPi comes with its own facilities or
# I'm going to hit a wall when I try to port this over to the RPi 3? Might need to
# reconfigure the stack so a RPi >= 4 is the main-node?
#export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig
#export CC="ccache gcc" CXX="ccache g++"
#declare -x PATH="/usr/lib64/ccache:$PATH"
autoreconf --install
./configure
# Ran out of memory (checked `dmesg` after failure and saw out of memeory)
#make -j4
# Ran out of memory on RPi 3B, will upgrade to RPi 4 for building...
make -j1
sudo make install
echo "/usr/local/lib/hooks" > /etc/ld.so.conf.d/kea.conf
ldconfig

# Will need to install arm-64 OS for RPi3 for the dhcp server to work
echo "Setting up eth0 static networking..." >> install.log
# Ignore eth0 in dhcpcd client
sudo echo "denyinterfaces eth0" >> /etc/dhcpcd.conf

cat << EOF | sudo tee /etc/network/interfaces.d/eth0
allow-hotplug eth0
iface eth0 inet static
    address 10.0.0.1
    netmask 255.255.255.0
    broadcast 10.0.0.255
    gateway 10.0.0.1
EOF

echo "Grabbing binary..." >> install.log
scp ~/Downloads/kea-dhcp4 main-node:/home/pi/

echo "Setting up DHCP Server..." >> install.log
cat << EOF | sudo tee /etc/kea/kea-dhcp4.cnf
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
EOF

# TODO: Might need to setup the exe as a service?

echo "Restarting kea-dhcp4-server..." >> install.log
sudo systemctl restart kea-dhcp4-server

# IP Forwarding for masquerading
echo "Enabling port forwarding..." >> install.log
sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sudo sysctl net.ipv4.ip_forward=1

# Firewall config
echo "Setting up NFTables..." >> install.log
sudo nft add table nat
sudo nft -- add chain nat prerouting { type nat hook prerouting priority -100 \; }
sudo nft add chain nat postrouting { type nat hook postrouting priority 100 \; }
sudo nft add rule nat postrouting oifname "wlan0" masquerade
sudo nft list ruleset > /etc/nftables.conf

# Start up NFTables
sudo systemctl enable nftables
sudo systemctl start nftables

echo "...Finished install, rebooting" >> install.log
sudo reboot