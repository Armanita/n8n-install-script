#!/bin/bash

# رنگ‌ها برای نمایش بهتر
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # بدون رنگ

# 1. به‌روزرسانی سیستم
echo -e "${BLUE}1. به‌روزرسانی سیستم...${NC}"
sudo apt update

# 2. نصب پیش‌نیازها
echo -e "${BLUE}2. نصب پیش‌نیازها...${NC}"
sudo apt install -y ca-certificates curl gnupg

# 3. ساخت پوشه برای keyrings
echo -e "${BLUE}3. ساخت پوشه keyrings...${NC}"
sudo install -m 0755 -d /etc/apt/keyrings

# 4. دانلود و ذخیره GPG Key داکر
echo -e "${BLUE}4. دانلود و ذخیره GPG Key داکر...${NC}"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o docker.gpg
sudo mv docker.gpg /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# 5. اضافه کردن Repository داکر
echo -e "${BLUE}5. اضافه کردن Repository داکر...${NC}"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 6. به‌روزرسانی مجدد و نصب Docker و پلاگین‌هایش
echo -e "${BLUE}6. به‌روزرسانی و نصب Docker و پلاگین‌ها...${NC}"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 7. نصب docker-compose دستی (نسخه جدیدتر)
echo -e "${BLUE}7. نصب docker-compose دستی...${NC}"
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 8. ساخت پوشه n8n و ورود به آن
echo -e "${BLUE}8. ساخت پوشه n8n و ورود به آن...${NC}"
mkdir -p ~/n8n
cd ~/n8n

# 9. ساخت پوشه داده n8n
echo -e "${BLUE}9. ساخت پوشه n8n_data و تغییر مالکیت آن...${NC}"
mkdir -p n8n_data
sudo chown 1000:1000 n8n_data

# 10. دریافت دامنه از کاربر
echo -e "${BLUE}10. لطفاً دامنه خود را وارد کنید (مثلاً n8n.example.com):${NC}"
read -p "دامنه: " DOMAIN

# 11. ساخت فایل docker-compose.yml
echo -e "${BLUE}11. ساخت فایل docker-compose.yml...${NC}"
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

# 12. نصب و راه‌اندازی اولیه Nginx بدون SSL
echo -e "${BLUE}12. نصب و پیکربندی اولیه Nginx بدون SSL...${NC}"
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

# 13. نصب Certbot و گرفتن گواهی SSL
echo -e "${BLUE}13. نصب Certbot و گرفتن گواهی SSL...${NC}"
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d $DOMAIN

# 14. تست تمدید خودکار گواهی
echo -e "${BLUE}14. تست تمدید خودکار گواهی SSL (Dry Run)...${NC}"
sudo certbot renew --dry-run

# 15. راه‌اندازی Docker Compose
echo -e "${BLUE}15. راه‌اندازی Docker Compose...${NC}"
docker-compose down
docker-compose up -d

# پایان
echo -e "${GREEN}✅ نصب و راه‌اندازی کامل شد! n8n اکنون از طریق https://$DOMAIN در دسترس است.${NC}"
