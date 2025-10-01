# AWS Linux 2023 - Web Application Stack Installation

Automated installation script for setting up a complete web application stack on AWS Linux 2023.

## 📋 Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Services Included](#services-included)
- [Post-Installation](#post-installation)
- [Uninstallation](#uninstallation)
- [Troubleshooting](#troubleshooting)

## ✨ Features

- **Interactive Menu**: Choose which services to install
- **Version Selection**: Select PHP and Node.js versions during installation
- **Automated Configuration**: Services are configured and started automatically
- **MySQL Setup**: Automatic database and user creation
- **Uninstall Support**: Complete removal script for testing purposes

## 📦 Prerequisites

- AWS Linux 2023 instance
- Root access (sudo privileges)
- Internet connection

## 🚀 Installation

### 1. Download the Scripts

```bash
# Download install script
curl -O https://your-repo/aws-linux-2023/install.sh
chmod +x install.sh

# Download uninstall script (optional)
curl -O https://your-repo/aws-linux-2023/uninstall.sh
chmod +x uninstall.sh
```

### 2. Run Installation

```bash
sudo ./install.sh
```

## 📖 Usage

### Installation Menu

When you run the script, you'll see an interactive menu:

```
AWS Linux 2023 - Service Installation Script
==========================================
Select services to install:
1. PHP + Nginx + PHP-FPM + Composer
2. MySQL
3. Supervisor
4. Nginx + NVM + Node + Yarn + PM2
5. All of the above

Enter your choices (comma-separated, e.g., 1,2,3):
```

### Installation Options

#### Option 1: PHP + Nginx + PHP-FPM + Composer

**PHP Version Selection:**
- PHP 8.1
- PHP 8.2 (recommended)
- PHP 8.3

**Included Extensions:**
- mysqlnd, pdo, mbstring, xml, gd, zip
- opcache, intl, bcmath, process
- common, sodium, cli, fpm

**Configuration:**
- Nginx web server
- PHP-FPM configured and running
- Composer installed globally

#### Option 2: MySQL

**Setup Process:**
1. Select MySQL root password
2. Enter database name
3. Enter database user
4. Enter database user password

**What's Installed:**
- MySQL 8.0 Community Server
- Automatic database creation
- User with full privileges on specified database

#### Option 3: Supervisor

**Features:**
- Process control system
- Systemd service enabled
- Configuration directory: `/etc/supervisor/conf.d/`

#### Option 4: Nginx + NVM + Node + Yarn + PM2

**Node.js Version Selection:**
- LTS (Long Term Support)
- Node.js 18.x
- Node.js 20.x
- Node.js 22.x

**Included Tools:**
- Nginx web server
- NVM (Node Version Manager) v0.39.7
- Node.js (selected version)
- Yarn package manager
- PM2 process manager

#### Option 5: All Services

Installs all services listed above with interactive version selection.

## 🔧 Services Included

### PHP Stack

```bash
# Check PHP version
php -v

# Check PHP-FPM status
sudo systemctl status php-fpm

# PHP-FPM service commands
sudo systemctl start php-fpm
sudo systemctl stop php-fpm
sudo systemctl restart php-fpm

# Check Composer
composer --version
```

**Configuration Files:**
- PHP: `/etc/php.ini`
- PHP-FPM: `/etc/php-fpm.d/www.conf`

### Nginx

```bash
# Check Nginx status
sudo systemctl status nginx

# Nginx service commands
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx

# Test configuration
sudo nginx -t
```

**Configuration Files:**
- Main config: `/etc/nginx/nginx.conf`
- Sites config: `/etc/nginx/conf.d/`
- Web root: `/usr/share/nginx/html`

### MySQL

```bash
# Login to MySQL
mysql -u root -p

# Login as created user
mysql -u your_username -p your_database

# Check MySQL status
sudo systemctl status mysqld

# MySQL service commands
sudo systemctl start mysqld
sudo systemctl stop mysqld
sudo systemctl restart mysqld
```

**Configuration Files:**
- Main config: `/etc/my.cnf`
- Additional configs: `/etc/my.cnf.d/`
- Data directory: `/var/lib/mysql`

**Important MySQL Information:**
- Root password: As entered during installation
- Database: Created automatically
- User: Has full privileges on specified database

### Supervisor

```bash
# Check Supervisor status
sudo systemctl status supervisord

# Supervisor service commands
sudo systemctl start supervisord
sudo systemctl stop supervisord
sudo systemctl restart supervisord

# Supervisor control
sudo supervisorctl status
sudo supervisorctl reread
sudo supervisorctl update
```

**Configuration Files:**
- Main config: `/etc/supervisord.conf`
- Program configs: `/etc/supervisor/conf.d/`
- Logs: `/var/log/supervisor/`

**Example Program Configuration:**

Create `/etc/supervisor/conf.d/myapp.conf`:
```ini
[program:myapp]
command=/path/to/your/app
directory=/path/to/working/dir
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/myapp.err.log
stdout_logfile=/var/log/supervisor/myapp.out.log
user=ec2-user
```

Then reload:
```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start myapp
```

### Node.js Stack (via NVM)

```bash
# Switch to your user (not root)
# NVM is installed per-user

# Check Node version
node --version

# Check npm version
npm --version

# Check Yarn version
yarn --version

# Check PM2 version
pm2 --version

# NVM commands
nvm list
nvm use 20
nvm install 18
nvm alias default 20
```

**Important Notes:**
- NVM is installed in user's home: `~/.nvm`
- Must be run as the user (not root)
- Automatically loaded in `.bashrc`

**PM2 Commands:**

```bash
# Start application
pm2 start app.js --name myapp

# List applications
pm2 list

# Monitor
pm2 monit

# Logs
pm2 logs

# Stop/restart
pm2 stop myapp
pm2 restart myapp

# Auto-start on boot
pm2 startup
pm2 save
```

## 🔐 Post-Installation

### 1. Firewall Configuration

```bash
# Allow HTTP
sudo firewall-cmd --permanent --add-service=http

# Allow HTTPS
sudo firewall-cmd --permanent --add-service=https

# Allow MySQL (if needed)
sudo firewall-cmd --permanent --add-port=3306/tcp

# Reload firewall
sudo firewall-cmd --reload
```

### 2. Security Hardening

**MySQL:**
```bash
# Run security script
sudo mysql_secure_installation
```

**PHP:**
Edit `/etc/php.ini`:
```ini
expose_php = Off
display_errors = Off
log_errors = On
```

### 3. Configure Your Application

**For PHP Applications:**

1. Place your code in `/usr/share/nginx/html` or create a new site:

```nginx
# /etc/nginx/conf.d/mysite.conf
server {
    listen 80;
    server_name example.com;
    root /var/www/mysite;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

2. Reload Nginx:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

**For Node.js Applications:**

1. Deploy your application
2. Start with PM2:
```bash
cd /path/to/your/app
pm2 start app.js --name myapp
pm2 startup
pm2 save
```

3. Configure Nginx as reverse proxy:
```nginx
# /etc/nginx/conf.d/nodeapp.conf
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 🗑️ Uninstallation

To remove all installed services (useful for testing):

```bash
sudo ./uninstall.sh
```

**Warning:** This will:
- Stop and remove all installed services
- Delete MySQL databases (you'll be prompted to confirm)
- Remove configuration files
- Remove NVM and Node.js
- Clean up package cache

The script will ask for confirmation before:
1. Starting the uninstallation process
2. Removing Nginx web files

## 🔍 Troubleshooting

### PHP-FPM Not Starting

```bash
# Check logs
sudo journalctl -xeu php-fpm

# Check configuration
sudo php-fpm -t

# Verify socket/port
sudo netstat -tulpn | grep php-fpm
```

### Nginx Configuration Issues

```bash
# Test configuration
sudo nginx -t

# Check error logs
sudo tail -f /var/log/nginx/error.log

# Verify ports
sudo netstat -tulpn | grep nginx
```

### MySQL Connection Issues

```bash
# Reset root password if needed
sudo systemctl stop mysqld
sudo mysqld_safe --skip-grant-tables &
mysql -u root
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'NewPassword';
mysql> FLUSH PRIVILEGES;
mysql> exit
sudo systemctl restart mysqld
```

### Node.js/NVM Issues

```bash
# Reload NVM
source ~/.nvm/nvm.sh

# Verify NVM installation
nvm --version

# Reinstall Node
nvm install node
nvm use node

# Check environment
echo $NVM_DIR
```

### Supervisor Not Running

```bash
# Check if service is active
sudo systemctl status supervisord

# Check supervisor logs
sudo tail -f /var/log/supervisor/supervisord.log

# Reload configuration
sudo supervisorctl reread
sudo supervisorctl update
```

### Permission Issues

```bash
# Fix web directory permissions
sudo chown -R nginx:nginx /usr/share/nginx/html
sudo chmod -R 755 /usr/share/nginx/html

# Fix PHP-FPM socket permissions
sudo chown nginx:nginx /run/php-fpm/www.sock
```

## 📝 Version Information

- **Script Version**: 1.0
- **Target OS**: AWS Linux 2023
- **PHP Versions**: 8.1, 8.2, 8.3
- **MySQL Version**: 8.0
- **Node.js Versions**: LTS, 18.x, 20.x, 22.x
- **NVM Version**: 0.39.7
- **Supervisor**: Latest (via pip3)

## 📄 File Locations Reference

| Service | Config | Logs | Data |
|---------|--------|------|------|
| Nginx | `/etc/nginx/` | `/var/log/nginx/` | `/usr/share/nginx/html` |
| PHP | `/etc/php.ini` | `/var/log/php-fpm/` | - |
| MySQL | `/etc/my.cnf` | `/var/log/mysqld.log` | `/var/lib/mysql` |
| Supervisor | `/etc/supervisord.conf` | `/var/log/supervisor/` | - |
| NVM | `~/.nvm` | - | `~/.nvm/versions/node/` |

## 🤝 Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review service logs
3. Verify AWS Linux 2023 compatibility

## ⚠️ Important Notes

1. **Root Access**: Always run installation script with `sudo`
2. **User Context**: NVM/Node commands should be run as regular user, not root
3. **Passwords**: Use strong passwords for MySQL
4. **Backup**: Always backup data before running uninstall script
5. **Testing**: Test on non-production environments first
6. **Updates**: Keep services updated with `sudo dnf update`

## 🔄 Service Management Quick Reference

```bash
# Check all services status
sudo systemctl status nginx php-fpm mysqld supervisord

# Restart all services
sudo systemctl restart nginx php-fpm mysqld supervisord

# Enable all services on boot
sudo systemctl enable nginx php-fpm mysqld supervisord

# View all logs
sudo journalctl -xe
```
