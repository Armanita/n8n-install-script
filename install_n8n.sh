#!/bin/bash

# 1. Update system
echo "1. Updating system..."
sudo apt update

# 2. Install prerequisites
echo "2. Installing prerequisites..."
sudo apt install -y ca-certificates curl gnupg

# 3. Create keyrings directory
echo "3. Creating keyrings directory..."
sudo install -m 0755 -d /etc/apt/keyrings

# 4. Download and store Docker GPG Key
echo "4. Downloading and storing Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o docker.gpg
sudo mv docker.gpg /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 5. Add Docker repository
echo "5. Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 6. Update and install Docker packages
echo "6. Updating and installing Docker packages..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 7. Install docker-compose manually
echo "7. Installing docker-compose manually..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 8. Create n8n directory and navigate into it
echo "8. Creating n8n directory and navigating into it..."
mkdir -p ~/n8n
cd ~/n8n

# 9. Create n8n_data directory and set permissions
echo "9. Creating n8n_data directory and setting permissions..."
mkdir -p n8n_data
sudo chown 1000:1000 n8n_data

# 10. Get domain from user
echo "10. Please enter your domain (e.g., n8n.example.com):"
read -p "Domain: " DOMAIN

# 11. Create docker-compose.yml file
echo "11. Creating docker-compose.yml file..."
cat > docker-compose.yml <<EOF
version: "3"

services:
  n8n:
    image: n8nio/n8n
    restart: always
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=yourStrongPassword
      - WEBHOOK_URL=https://$DOMAIN
      - WEBHOOK_TUNNEL_URL=https://$DOMAIN
      - N8N_HOST=$DOMAIN
      - N8N_PORT=5678
      - N8N_RUNNERS_ENABLED=true    
    volumes:
      - ./n8n_data:/home/node/.n8n

volumes:
  n8n_data:
    driver: local
EOF

# 12. Install and configure Nginx
echo "12. Installing and configuring Nginx..."
sudo apt install nginx -y
cat > /etc/nginx/sites-available/n8n <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:5678;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 13. Install Certbot and obtain SSL certificate
echo "13. Installing Certbot and obtaining SSL certificate..."
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d $DOMAIN

# 14. Test SSL certificate auto-renewal
echo "14. Testing SSL certificate auto-renewal (Dry Run)..."
sudo certbot renew --dry-run

# 15. Start Docker Compose services
echo "15. Starting Docker Compose services..."
docker-compose down
docker-compose up -d

# Done
echo "✅ Installation and setup completed! n8n is now available at https://$DOMAIN"
