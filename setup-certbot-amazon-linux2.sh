#!/bin/bash

# Usage: ./setup-certbot-amazon-linux2.sh yourdomain.com

DOMAIN=$1

if [[ -z "$DOMAIN" ]]; then
  echo "Usage: $0 yourdomain.com"
  exit 1
fi

# Update the system
sudo yum update -y

# Enable the EPEL repository
sudo amazon-linux-extras install epel -y

# Install Certbot and the Nginx plugin
sudo yum install -y certbot python2-certbot-nginx

# Obtain and install the SSL certificate
sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN"

# Test automatic certificate renewal
sudo certbot renew --dry-run
