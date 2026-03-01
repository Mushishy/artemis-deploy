#!/bin/bash

sudo su

apt install git openssl -y 

if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    curl -fsSL https://nodejs.org/dist/v25.6.0/node-v25.6.0-linux-x64.tar.xz -o node-v25.6.0-linux-x64.tar.xz
    tar -C /usr/local --strip-components 1 -xJf node-v25.6.0-linux-x64.tar.xz
    rm node-v25.6.0-linux-x64.tar.xz
fi

if [ ! -d "/opt/artemis-frontend" ]; then
    git clone https://github.com/Mushishy/artemis-frontend.git /opt/artemis-frontend
fi

cd /opt/artemis-frontend
rm -rf .svelte-kit/ node_modules/ build/

cp .env.example .env
cp ./artemis-frontend.service /etc/systemd/system
chown -R www-data:www-data /opt/artemis-frontend

npm install --legacy-peer-deps
npm run build

systemctl daemon-reload

systemctl start artemis-frontend.service
systemctl enable artemis-frontend.service
systemctl status artemis-frontend.service