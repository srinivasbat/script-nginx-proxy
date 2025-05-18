#!/bin/bash

# Usage: ./create-nginx-reverse-proxy.sh domain.com backend_port

DOMAIN=$1
PORT=$2

if [[ -z "$DOMAIN" || -z "$PORT" ]]; then
  echo "Usage: $0 domain.com backend_port"
  exit 1
fi

SITES_AVAILABLE="/etc/nginx/sites-available"
SITES_ENABLED="/etc/nginx/sites-enabled"
CONFIG_PATH="$SITES_AVAILABLE/${DOMAIN}.conf"
ENABLED_PATH="$SITES_ENABLED/${DOMAIN}.conf"

# 1. Create directories if they don't exist
if [ ! -d "$SITES_AVAILABLE" ]; then
  sudo mkdir -p "$SITES_AVAILABLE"
fi

if [ ! -d "$SITES_ENABLED" ]; then
  sudo mkdir -p "$SITES_ENABLED"
fi

# 2. Create Nginx reverse proxy config
sudo bash -c "cat > $CONFIG_PATH" <<EOF
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    access_log /var/log/nginx/${DOMAIN}.access.log;
    error_log  /var/log/nginx/${DOMAIN}.error.log;

    location / {
        proxy_pass http://127.0.0.1:${PORT};
        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_read_timeout 60;
        proxy_connect_timeout 60;
        proxy_redirect off;
    }
}
EOF

# 3. Link config if not already linked
if [ ! -f "$ENABLED_PATH" ]; then
  sudo ln -s "$CONFIG_PATH" "$ENABLED_PATH"
else
  echo "Symlink already exists: $ENABLED_PATH"
fi

# 4. Test and reload Nginx
echo "Testing Nginx config..."
sudo nginx -t

if [ $? -eq 0 ]; then
  echo "Reloading Nginx..."
  sudo systemctl reload nginx
  echo "✅ Reverse proxy for http://${DOMAIN} -> http://localhost:${PORT} is live."
else
  echo "❌ Nginx config test failed. Please fix errors above."
fi

