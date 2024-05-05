#!/bin/sh

# Little script to:
# 0. Pull down Python
# 1. Verify Python download
# 2. Build Python
# 3. Deploy Python
PYTHON="3.12.2"

echo "Installing build dependencies"
sudo apt-get install build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev wget -y

echo "Installing Python $PYTHON"
if ! test -f Python-$PYTHON.tgz; then
    wget "https://www.python.org/ftp/python/$PYTHON/Python-$PYTHON.tgz"
fi
# Using Sigstore: https://www.python.org/download/sigstore/
if ! test -f Python-$PYTHON.tgz.sigstore; then
    wget "https://www.python.org/ftp/python/$PYTHON/Python-$PYTHON.tgz.sigstore"
fi

if [ $# -gt 1 ]; then
    echo "Full build"
    # Install Rust, Python dependency
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source ~/.cargo/env
    # Install sigstore dependencies
    python -m pip install -r https://raw.githubusercontent.com/sigstore/sigstore-python/main/install/requirements.txt
else
    # Simply install
    echo "Pip install"
    python -m pip install sigstore
fi

# Verify the package
if ! python -m sigstore verify identity \
  --bundle Python-$PYTHON.tgz.sigstore \
  --cert-identity thomas@python.org \
  --cert-oidc-issuer https://accounts.google.com \
  Python-$PYTHON.tgz; then
    echo "Failed to verify tarball, exiting!"
    exit 1
fi

# Clean to untar and start using
echo "Extracting tarball"
tar -xf Python-$PYTHON.tgz

if ! test -e Python-$PYTHON; then
    echo "Failed to untar package"
    exit 1
fi

echo "Building and install Python $PYTHON"
cd Python-$PYTHON
./configure --enable-optimizations
make
sudo make altinstall

echo "Setup Python for CLI use"
# sudo rm /usr/bin/python3
# TODO: How to get this to work with different versions of Python?
# sudo ln -s /usr/bin/python3.12 python3