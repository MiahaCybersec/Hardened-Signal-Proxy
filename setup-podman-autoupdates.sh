#!/bin/bash

# Create named volumes if they don't exist
podman volume create caddy_data
podman volume create caddy_config
echo "Named volumes 'caddy_data' and 'caddy_config' have been created."

# Function to create a file with content
create_file() {
    local filename=$1
    local content=$2
    echo "$content" | sudo tee "$filename" > /dev/null
    echo "Created $filename"
}

# Create the service file for the Caddy Signal Proxy container
hardened_signal_proxy_service_content="[Unit]
Description=Caddy Signal Proxy Container
Wants=network-online.target
After=network-online.target
RequiresMountsFor=%t/containers

[Service]
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
TimeoutStopSec=70
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run --cidfile=%t/%n.ctr-id --cgroups=no-conmon --sdnotify=conmon --replace -d \
    --name hardened-signal-proxy \
    -p 80:80 \
    -p 443:443 \
    --restart unless-stopped \
    -v ${PWD}/config/caddy.json:/etc/caddy/caddy.json:ro,Z \
    -v caddy_data:/data:Z \
    -v caddy_config:/config:ro,Z \
    --security-opt=apparmor=podman \
    --cap-add SETUID \
    --cap-add SETGID \
    --label \"io.containers.autoupdate=image\" \
    ghcr.io/miahacybersec/hardened-signal-proxy:nightly \
    run --config /etc/caddy/caddy.json
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
Type=notify
NotifyAccess=all

[Install]
WantedBy=default.target"

create_file "/etc/systemd/system/hardened-signal-proxy.service" "$hardened_signal_proxy_service_content"

# Create the timer file for auto-update
podman_auto_update_timer_content="[Unit]
Description=Podman auto-update timer

# Set to run at 00:30 UTC daily because the rebuild occurs nightly at 00:00 UTC.
# This 30-minute delay ensures we're pulling the latest build.
[Timer]
OnCalendar=*-*-* 00:30:00 UTC
Persistent=true

[Install]
WantedBy=timers.target"

create_file "/etc/systemd/system/podman-auto-update.timer" "$podman_auto_update_timer_content"

# Create the service file for auto-update
podman_auto_update_service_content="[Unit]
Description=Podman auto-update service

[Service]
ExecStart=/usr/bin/podman auto-update

[Install]
WantedBy=multi-user.target"

create_file "/etc/systemd/system/podman-auto-update.service" "$podman_auto_update_service_content"

# Reload systemd, enable and start the services
sudo systemctl daemon-reload
sudo systemctl enable --now hardened-signal-proxy.service
sudo systemctl enable --now podman-auto-update.timer

echo "Systemd files created and services enabled. Your Podman container is now set up for automatic updates at 00:30 UTC daily."