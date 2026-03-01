# deploy golang
#!/bin/bash

sudo su

apt install git openssl -y 

check if go version exist and is 1.25.1
if not download and install go 1.25.1
wget https://go.dev/dl/go1.25.1.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.25.1.linux-amd64.tar.gz
rm go1.25.1.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
fi 

if [ ! -d "/opt/scenario-manager-api" ]; then
git clone https://github.com/Mushishy/scenario-manager-api /opt/
fi

# create certs
mkdir -p /opt/scenario-manager-api/certs
openssl req -x509 -newkey rsa:4096 -sha256 -nodes -days 3650 \
  -keyout /opt/scenario-manager-api/certs/pve-ssl.key \
  -out /opt/scenario-manager-api/certs/pve-ssl.pem \
  -subj "/C=SK/ST=Slovakia/L=Bratislava/O=STU/OU=ARTEMIS/CN=100.67.101.72"

# 
mkdir -p /opt/scenario-manager-api/data/pools
mkdir -p /opt/scenario-manager-api/data/scenarios
mkdir -p /opt/scenario-manager-api/data/topologies
cp /opt/scenario-manager-api/server/data/ctfd_topology.yml /opt/scenario-manager-api/data

cp /opt/scenario-manager-api/server/.env.example /opt/scenario-manager-api/.env

# build golang
#!/bin/bash

# Build for Linux AMD64
echo "Building scenario-manager-api for Linux AMD64..."

cd server

# Clean previous builds
rm -f scenario-manager-api

# Check if we're cross-compiling or building natively
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Building natively on Linux..."
    # Native build on Linux
    export CGO_ENABLED=1
    go build -ldflags="-w -s" -o scenario-manager-api .
else
    echo "Cross-compiling from $OSTYPE to Linux AMD64..."
    # Cross-compilation from macOS/Windows to Linux
    # For SQLite cross-compilation, we need to disable CGO or use a different approach
    export GOOS=linux
    export GOARCH=amd64
    export CGO_ENABLED=0

    go build -ldflags="-w -s" -o scenario-manager-api .
fi

if [ $? -eq 0 ]; then
    echo "Build successful! Binary created: server/scenario-manager-api"
    echo "File size: $(ls -lh scenario-manager-api | awk '{print $5}')"
    
    # Show binary info
    if command -v file >/dev/null 2>&1; then
        echo "Binary info: $(file scenario-manager-api)"
    fi
else
    echo "Build failed!"
    exit 1
fi

cp /opt/scenario-manager-api/server/scenario-manager-api /opt/scenario-manager-api/scenario-manager-api
cp /opt/scenario-manager-api//scenario-manager-api.service /etc/systemd/system/scenario-manager-api.service

chown -R ludus:ludus /opt/scenario-manager-api

# Start the service
systemctl start scenario-manager-api.service
systemctl enable scenario-manager-api.service
systemctl status scenario-manager-api.service

# deploy artemis-frontend
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

# deploy nginx

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