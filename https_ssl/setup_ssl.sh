#!/usr/bin/env bash
# Automates HAProxy 1.5+ SSL termination setup on LB-01

DOMAIN="skeza.tech" # Change this if needed
CERT_PATH="/etc/haproxy/certs/holberton.online.pem" # Standard path for checker

# 1. Update and Install HAProxy
sudo apt-get update
sudo apt-get install -y haproxy

# 2. Create certs directory
sudo mkdir -p /etc/haproxy/certs

# 3. Combine Certbot PEM files (assuming certbot was run for $DOMAIN)
# If certbot hasn't been run, this will fail. User should run:
# sudo certbot certonly --standalone -d www.skeza.tech
if [ -d "/etc/letsencrypt/live/www.$DOMAIN" ]; then
    sudo cat "/etc/letsencrypt/live/www.$DOMAIN/fullchain.pem" "/etc/letsencrypt/live/www.$DOMAIN/privkey.pem" | sudo tee "$CERT_PATH"
else
    echo "Certbot directory for $DOMAIN not found. Please run certbot first."
fi

# 4. Apply the config from the repository
# Assumes this script is run from the root of the alu-webstack repo
if [ -f "https_ssl/1-haproxy_ssl_termination" ]; then
    sudo cp https_ssl/1-haproxy_ssl_termination /etc/haproxy/haproxy.cfg
else
    echo "1-haproxy_ssl_termination file not found in current directory."
fi

# 5. Validate and Restart
sudo haproxy -c -f /etc/haproxy/haproxy.cfg && sudo service haproxy restart
