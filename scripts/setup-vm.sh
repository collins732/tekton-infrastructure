#!/bin/bash

# Script exécuté automatiquement au démarrage de la VM
# Il installe Node.js, clone le repo et lance Next.js

set -e

echo "=========================================="
echo "Installation de Node.js et dépendances..."
echo "=========================================="

# Mettre à jour le système
apt-get update
apt-get upgrade -y

# Installer Node.js 18
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Installer Git
apt-get install -y git

# Vérifier les versions
node --version
npm --version
git --version

echo "=========================================="
echo "Clonage du repo GitHub..."
echo "=========================================="

# Créer un dossier pour l'app
mkdir -p /opt/vulnscanner
cd /opt/vulnscanner

# Cloner le repo (public pour le moment)
git clone ${github_repo_url} app

cd app

echo "=========================================="
echo "Installation des dépendances Next.js..."
echo "=========================================="

npm install

echo "=========================================="
echo "Build de l'application Next.js..."
echo "=========================================="

npm run build

echo "=========================================="
echo "Démarrage de Next.js en production..."
echo "=========================================="

# Créer un service systemd pour lancer Next.js automatiquement
cat > /etc/systemd/system/nextjs.service <<EOF
[Unit]
Description=Next.js Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/vulnscanner/app
Environment="HOSTNAME=0.0.0.0"
ExecStart=/usr/bin/npm start
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Activer et démarrer le service
systemctl daemon-reload
systemctl enable nextjs
systemctl start nextjs

echo "=========================================="
echo "Installation de Nginx (reverse proxy)..."
echo "=========================================="

# Installer Nginx
apt-get install -y nginx

# Configurer Nginx comme reverse proxy vers Next.js
cat > /etc/nginx/sites-available/nextjs <<'NGINX_EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_EOF

# Activer la configuration
ln -sf /etc/nginx/sites-available/nextjs /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Tester et redémarrer Nginx
nginx -t
systemctl restart nginx
systemctl enable nginx

echo "=========================================="
echo "Installation terminée !"
echo "Next.js accessible sur :"
echo "  - Port 3000 (direct)"
echo "  - Port 80 (via Nginx)"
echo "=========================================="