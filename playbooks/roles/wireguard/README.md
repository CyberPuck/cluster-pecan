# WireGuard Role

This role will setup a working wireguard server and client connection file.
The networking rules for the server are established in the `networking` role
using net filter tables.

Check `./defaults/main.yml` for the default network and configuration settings.
By default a file `./playbooks/wg0.peer.conf` will be written to the host on
the successful completion of this role. Use that file to connect to the
wireguard server.

## Client Connection

On a linux host simply run:

```bash
sudo apt-get install wireguard
wg-quick up playbooks/wg0.peer.conf
```

A tunnel should be established to the server.
