#!/bin/bash

# Usage: ./setup-certbot.sh yourdomain.com

DOMAIN=$1

if [[ -z "$DOMAIN" ]]; then
  echo "Usage: $0 yourdomain.com"
  exit 1
fi

# Detect OS
. /etc/os-release

echo "Detected OS: $NAME $VERSION_ID"

# Function to install Certbot on Amazon Linux 2
install_certbot_amzn2() {
  sudo yum update -y
  sudo amazon-linux-extras install epel -y
  sudo yum install -y certbot python3-certbot-nginx
}

# Function to install Certbot on Amazon Linux 2023
install_certbot_amzn2023() {
  sudo dnf update -y
  sudo dnf install -y certbot python3-certbot-nginx
}

# Function to install Certbot on Ubuntu
install_certbot_ubuntu() {
  sudo apt update -y
  sudo apt install -y certbot python3-certbot-nginx
}

# Install based on detected OS
if [[ "$ID" == "amzn" ]]; then
  if [[ "$VERSION_ID" == "2" ]]; then
    install_certbot_amzn2
  elif [[ "$VERSION_ID" == "2023" ]]; then
    install_certbot_amzn2023
  else
    echo "Unsupported Amazon Linux version: $VERSION_ID"
    exit 1
  fi
elif [[ "$ID" == "ubuntu" ]]; then
  install_certbot_ubuntu
else
  echo "Unsupported OS: $ID"
  exit 1
fi

# Obtain certificate with manual input
echo "Launching Certbot... (you'll be prompted for email, agreement, etc.)"
sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN"

# Test automatic certificate renewal
echo "Testing renewal..."
sudo certbot renew --dry-run

echo "Setup complete."
