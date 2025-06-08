#!/bin/bash

# Usage: ./create-nginx-reverse-proxy.sh domain.com backend_port

DOMAIN=$1
PORT=$2

if [[ -z "$DOMAIN" || -z "$PORT" ]]; then
  echo "❌ Usage: $0 domain.com backend_port"
  exit 1
fi

SITES_AVAILABLE="/etc/nginx/sites-available"
SITES_ENABLED="/etc/nginx/sites-enabled"
CONFIG_PATH="${SITES_AVAILABLE}/${DOMAIN}.conf"
ENABLED_PATH="${SITES_ENABLED}/${DOMAIN}.conf"
NGINX_CONF="/etc/nginx/nginx.conf"

echo "🔧 Setting up reverse proxy for ${DOMAIN} → localhost:${PORT}"

# 1. Create directories if they don't exist
sudo mkdir -p "$SITES_AVAILABLE" "$SITES_ENABLED"

# 2. Check for existing config using server_name (in all confs)
if sudo grep -R "server_name\s\+\(www\.\)\?${DOMAIN}\b" "$SITES_AVAILABLE" "$SITES_ENABLED" /etc/nginx/conf.d/ 2>/dev/null | grep -q .; then
  echo "❌ Config already exists for $DOMAIN. Aborting."
  exit 1
fi

# 3. Create the config
sudo tee "$CONFIG_PATH" > /dev/null <<EOF
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

# 4. Create symlink if not already linked
if [ ! -f "$ENABLED_PATH" ]; then
  echo "🔗 Linking config to sites-enabled"
  sudo ln -s "$CONFIG_PATH" "$ENABLED_PATH"
else
  echo "🔁 Symlink already exists: $ENABLED_PATH"
fi

# 5. Ensure include line exists in nginx.conf (only once)
if ! grep -q 'include /etc/nginx/sites-enabled/\*;' "$NGINX_CONF"; then
  echo "➕ Adding include /etc/nginx/sites-enabled/*.conf; to nginx.conf"
  sudo sed -i '/http {/a \    include /etc/nginx/sites-enabled/*.conf;' "$NGINX_CONF"
else
  echo "✅ nginx.conf already includes sites-enabled/*.conf"
fi

# 6. Test & Reload
echo "🧪 Testing Nginx configuration..."
if sudo nginx -t; then
  echo "🔄 Reloading Nginx..."
  sudo systemctl reload nginx
  echo "✅ Reverse proxy live: http://${DOMAIN} → http://localhost:${PORT}"
else
  echo "❌ Nginx config test failed. Fix errors and try again."
  exit 1
fi
