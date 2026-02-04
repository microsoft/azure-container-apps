#!/bin/bash
set -e

CONFIG_FILE="/etc/nginx/redirects.yaml"
NGINX_CONF="/etc/nginx/conf.d/default.conf"

# Start nginx config
cat > "$NGINX_CONF" << 'HEADER'
# Auto-generated from redirects.yaml - DO NOT EDIT DIRECTLY

# Health check endpoint
server {
    listen 80 default_server;
    server_name _;
    
    location /health {
        return 200 'healthy';
        add_header Content-Type text/plain;
    }
    
    # Catch-all for unknown hosts
    location / {
        return 404 'Unknown host';
        add_header Content-Type text/plain;
    }
}

HEADER

# Parse redirects.yaml and generate server blocks
count=$(yq '.redirects | length' "$CONFIG_FILE")

for ((i=0; i<count; i++)); do
    host=$(yq ".redirects[$i].host" "$CONFIG_FILE")
    target=$(yq ".redirects[$i].target" "$CONFIG_FILE")
    preserve_path=$(yq ".redirects[$i].preserve_path // false" "$CONFIG_FILE")
    
    # Remove trailing slash from target for consistent handling
    target="${target%/}"
    
    if [ "$preserve_path" = "true" ]; then
        redirect_target="${target}\$request_uri"
    else
        redirect_target="${target}"
    fi
    
    cat >> "$NGINX_CONF" << SERVERBLOCK
# Redirect: $host -> $target
server {
    listen 80;
    server_name $host;
    
    location / {
        return 301 $redirect_target;
    }
}

SERVERBLOCK

    echo "Configured redirect: $host -> $target (preserve_path: $preserve_path)"
done

echo "Generated nginx config with $count redirect(s)"
