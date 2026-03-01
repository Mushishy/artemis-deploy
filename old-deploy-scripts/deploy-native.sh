#!/bin/bash

sudo su 

# Install system dependencies
apt update
apt install -y nginx openssl

mkdir -p /etc/nginx/ssl

# Generate SSL certificates if they don't exist
if [ ! -f /etc/nginx/ssl/artemis.key ]; then
    openssl req -x509 -newkey rsa:4096 -sha256 -nodes -days 3650 \
        -keyout /etc/nginx/ssl/artemis.key \
        -out /etc/nginx/ssl/artemis.crt \
        -subj "/C=SK/ST=Slovakia/L=Bratislava/O=STU/OU=ARTEMIS/CN=artemis-frontend"
    chmod 640 /etc/nginx/ssl/artemis.key
    chmod 644 /etc/nginx/ssl/artemis.crt
    chown -R www-data:www-data /etc/nginx/ssl/
fi

cp nginx.conf /etc/nginx/nginx.conf
rm -f /etc/nginx/sites-enabled/*

nginx -t
systemctl restart nginx
systemctl enable nginx