# Hardened Signal Proxy

To run Hardened Signal Proxy, you will need a host that has ports 80 and 443 available and a domain name that points to that host.

# Container Setup

In the `sed` command below, replace `sub.my-domain.com` with the subdomain you want to host your Signal proxy at.

1. Install Podman (https://podman.io/docs/installation)
1. `git pull https://github.com/MiahaCybersec/Hardened-Signal-Proxy.git`
1. `podman pull ghcr.io/miahacybersec/hardened-signal-proxy:nightly`
1. `cd Hardened-Signal-Proxy`
1. `sed -i 's/sub.example.com/sub.my-domain.com/g' config/caddy.json`
1. `chmod +x ./setup-podman-autoupdates.sh`
1. `./setup-podman-autoupdates.sh`



# Hardening The Host

If you'd like to harden your server against memory corruption vulnerabilities, run the following commands. This will install [hardened_malloc](https://github.com/GrapheneOS/hardened_malloc) on your server and add it to your path automatically.

1. `chmod +x ./harden.sh`
2. `./harden.sh`

Your proxy is now running! You can share this with the URL `https://signal.tube/#<your_host_name>`
