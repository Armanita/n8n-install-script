# 🚀 Easy n8n Installation Script

> **🔧 One Click — Simple and Fast Setup!**  
> **✅ Install n8n with SSL in Minutes!**

---

## 📋 Prerequisites
Before using this script, make sure you have:
- A fresh **Ubuntu 20.04+** server (root access)
- A valid **domain name** pointing to your server
- Open ports **80** and **443** (for HTTP/HTTPS)

---

## 📥 Usage
1. **Clone the repository:**
   ```bash
   git clone https://github.com/Armanita/n8n-install-script.git
   cd n8n-install-script
Make the script executable (optional):

bash
Copy
Edit
chmod +x install_n8n.sh
Run the script:

bash
Copy
Edit
./install_n8n.sh
Follow the instructions to enter your domain name when prompted.

⚙️ What This Script Does
Updates your server packages

Installs Docker, Docker Compose

Installs and configures Nginx as a reverse proxy

Automatically sets up SSL with Let's Encrypt (Certbot)

Deploys n8n using Docker Compose

One-click ready-to-use deployment 🚀

📂 Folder Structure
Copy
Edit
n8n-install-script/
├── install_n8n.sh
└── README.md
✨ After Installation
Access your n8n instance at:

arduino
Copy
Edit
https://yourdomain.com
Default login:

Username: admin

Password: yourStrongPassword (you can change it later)

🛠️ Customize
Modify environment variables in docker-compose.yml if needed (e.g., username, password).

SSL certificates are auto-renewed with Certbot.

🤝 License
This project is open-sourced under the MIT License.

🔥 Created by Armanita with ❤️
