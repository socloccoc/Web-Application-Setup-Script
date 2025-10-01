# Ubuntu - Web Application Stack Installation

Automated installation script for setting up a complete web application stack on Ubuntu 20.04, 22.04, and 24.04.

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
- **MySQL Setup**: Automatic database and user creation with secure password handling
- **Ubuntu Version Detection**: Automatically detects Ubuntu version (20.04/22.04/24.04)
- **Uninstall Support**: Complete removal script for testing purposes

## 📦 Prerequisites

- Ubuntu 20.04, 22.04, or 24.04 LTS
- Root access (sudo privileges)
- Internet connection
- Minimum 1GB RAM (2GB+ recommended for full stack)

## 🚀 Installation

### 1. Download the Scripts

```bash
# Navigate to directory
cd /path/to/ubuntu

# Or download directly
curl -O https://your-repo/ubuntu/install.sh
curl -O https://your-repo/ubuntu/uninstall.sh

# Make executable
chmod +x install.sh uninstall.sh
```

### 2. Run Installation

```bash
sudo ./install.sh
```

## 📖 Usage

### Installation Menu

When you run the script, you'll see an interactive menu:

```
==========================================
Ubuntu - Service Installation Script
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
- Core: cli, fpm, common, mysql, pgsql, sqlite3
- Web: curl, mbstring, xml, gd, zip
- Performance: opcache
- Additional: intl, bcmath, soap, redis

**Configuration:**
- Nginx web server configured for PHP
- PHP-FPM running with Unix socket
- Composer installed globally
- Test PHP file created at `/var/www/html/info.php`

**Source:**
- PHP packages from Ondřej Surý's PPA (ppa:ondrej/php)

#### Option 2: MySQL

**Setup Process:**
1. Set MySQL root password (min 8 characters)
2. Optionally create database
3. Optionally create database user with privileges

**What's Installed:**
- MySQL 8.0 from Ubuntu repositories
- Automatic security configuration
- Database and user creation (if specified)

**Security Features:**
- Root password set during installation
- Anonymous users removed
- Remote root login disabled
- Test database removed

#### Option 3: Supervisor

**Features:**
- Process control system from Ubuntu repositories
- Systemd service enabled
- Configuration directory: `/etc/supervisor/conf.d/`
- Automatic startup on boot

#### Option 4: Nginx + NVM + Node + Yarn + PM2

**Node.js Version Selection:**
- LTS (Long Term Support - recommended)
- Node.js 18.x
- Node.js 20.x
- Node.js 22.x

**Included Tools:**
- Nginx web server
- NVM (Node Version Manager) v0.39.7
- Node.js (selected version)
- Yarn package manager (via npm)
- PM2 process manager (via npm)
- PM2 startup script configured

#### Option 5: All Services

Installs all services listed above with interactive version selection.

## 🔧 Services Included

### PHP Stack

```bash
# Check PHP version
php -v

# Check PHP-FPM status
sudo systemctl status php8.2-fpm

# PHP-FPM service commands
sudo systemctl start php8.2-fpm
sudo systemctl stop php8.2-fpm
sudo systemctl restart php8.2-fpm

# Check Composer
composer --version
```

**Configuration Files:**
- PHP: `/etc/php/8.2/cli/php.ini`
- PHP-FPM: `/etc/php/8.2/fpm/php.ini`
- Pool config: `/etc/php/8.2/fpm/pool.d/www.conf`
- Socket: `/var/run/php/php8.2-fpm.sock`

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
- Sites available: `/etc/nginx/sites-available/`
- Sites enabled: `/etc/nginx/sites-enabled/`
- Default site: `/etc/nginx/sites-available/default`
- Web root: `/var/www/html`

**Default PHP Configuration:**
```nginx
location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
}
```

### MySQL

```bash
# Login to MySQL
mysql -u root -p

# Login as created user
mysql -u your_username -p your_database

# Check MySQL status
sudo systemctl status mysql

# MySQL service commands
sudo systemctl start mysql
sudo systemctl stop mysql
sudo systemctl restart mysql
```

**Configuration Files:**
- Main config: `/etc/mysql/my.cnf`
- Additional configs: `/etc/mysql/mysql.conf.d/`
- Data directory: `/var/lib/mysql`
- Log files: `/var/log/mysql/`

**Important MySQL Information:**
- Root password: Set during installation
- Database: Created automatically (if specified)
- User: Has full privileges on specified database

### Supervisor

```bash
# Check Supervisor status
sudo systemctl status supervisor

# Supervisor service commands
sudo systemctl start supervisor
sudo systemctl stop supervisor
sudo systemctl restart supervisor

# Supervisor control
sudo supervisorctl status
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start program_name
sudo supervisorctl stop program_name
sudo supervisorctl restart program_name
```

**Configuration Files:**
- Main config: `/etc/supervisor/supervisord.conf`
- Program configs: `/etc/supervisor/conf.d/`
- Logs: `/var/log/supervisor/`

**Example Program Configuration:**

Create `/etc/supervisor/conf.d/myapp.conf`:
```ini
[program:myapp]
command=/usr/bin/php /var/www/myapp/artisan queue:work
directory=/var/www/myapp
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/myapp.err.log
stdout_logfile=/var/log/supervisor/myapp.out.log
user=www-data
numprocs=1
redirect_stderr=true
stopwaitsecs=3600
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
su - ubuntu  # or your username

# Check versions
node --version
npm --version
yarn --version
pm2 --version

# NVM commands
nvm --version
nvm list
nvm use 20
nvm install 18
nvm alias default 20
```

**Important Notes:**
- NVM installed in user's home: `~/.nvm`
- Must be run as regular user, not root
- Automatically loaded in `~/.bashrc`
- Each user needs separate NVM installation

**PM2 Commands:**

```bash
# Start application
pm2 start app.js --name myapp

# Start with options
pm2 start app.js --name myapp --instances 4 --exec-mode cluster

# List applications
pm2 list

# Monitor
pm2 monit

# Logs
pm2 logs
pm2 logs myapp

# Stop/restart/delete
pm2 stop myapp
pm2 restart myapp
pm2 delete myapp

# Save process list
pm2 save

# Auto-start on boot (already configured by script)
pm2 startup systemd
```

## 🔐 Post-Installation

### 1. Firewall Configuration

Ubuntu uses UFW (Uncomplicated Firewall):

```bash
# Enable UFW
sudo ufw enable

# Allow SSH (important!)
sudo ufw allow ssh
sudo ufw allow 22/tcp

# Allow HTTP and HTTPS
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow MySQL (if needed from external)
sudo ufw allow 3306/tcp

# Check status
sudo ufw status verbose
```

### 2. Security Hardening

**MySQL:**
```bash
# Already secured by script, but you can run again
sudo mysql_secure_installation
```

**PHP Security Settings:**

Edit `/etc/php/8.2/fpm/php.ini`:
```ini
expose_php = Off
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/php/error.log
allow_url_fopen = Off
allow_url_include = Off
```

**Nginx Security Headers:**

Edit `/etc/nginx/sites-available/default`:
```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
```

### 3. Configure Your Application

**For PHP Applications (Laravel example):**

```bash
# Create directory
sudo mkdir -p /var/www/myapp
sudo chown -R www-data:www-data /var/www/myapp

# Deploy application
cd /var/www/myapp
git clone your-repo .
composer install --no-dev --optimize-autoloader
php artisan key:generate
php artisan migrate

# Set permissions
sudo chown -R www-data:www-data /var/www/myapp
sudo chmod -R 755 /var/www/myapp
sudo chmod -R 775 /var/www/myapp/storage
sudo chmod -R 775 /var/www/myapp/bootstrap/cache
```

**Nginx Configuration:**
```nginx
# /etc/nginx/sites-available/myapp
server {
    listen 80;
    server_name example.com;
    root /var/www/myapp/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

**For Node.js Applications:**

```bash
# Deploy as regular user
su - ubuntu
cd ~
git clone your-repo myapp
cd myapp
yarn install
yarn build  # if needed

# Start with PM2
pm2 start npm --name myapp -- start
# or
pm2 start yarn --name myapp -- start
# or
pm2 start server.js --name myapp

# Save PM2 process list
pm2 save
```

**Nginx Reverse Proxy for Node.js:**
```nginx
# /etc/nginx/sites-available/nodeapp
server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
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
- Delete MySQL databases (you'll be prompted)
- Remove configuration files
- Remove NVM and Node.js
- Clean package cache
- Remove PPAs (Ondřej PHP PPA)

The script will ask for confirmation before:
1. Starting the uninstallation
2. Removing web files (`/var/www`)

## 🔍 Troubleshooting

### PHP-FPM Not Starting

```bash
# Check logs
sudo journalctl -xeu php8.2-fpm
sudo tail -f /var/log/php8.2-fpm.log

# Check configuration
sudo php-fpm8.2 -t

# Verify socket
ls -la /var/run/php/php8.2-fpm.sock

# Check permissions
sudo systemctl status php8.2-fpm
```

### Nginx Configuration Issues

```bash
# Test configuration
sudo nginx -t

# Check error logs
sudo tail -f /var/log/nginx/error.log

# Verify ports
sudo netstat -tulpn | grep :80
sudo ss -tulpn | grep :80

# Check if Apache is running (conflict)
sudo systemctl status apache2
sudo systemctl stop apache2
sudo systemctl disable apache2
```

### MySQL Connection Issues

```bash
# Check if MySQL is running
sudo systemctl status mysql

# Check MySQL error log
sudo tail -f /var/log/mysql/error.log

# Reset root password
sudo systemctl stop mysql
sudo mkdir -p /var/run/mysqld
sudo chown mysql:mysql /var/run/mysqld
sudo mysqld_safe --skip-grant-tables &
mysql -u root
mysql> FLUSH PRIVILEGES;
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'NewPassword';
mysql> exit
sudo systemctl restart mysql
```

### Node.js/NVM Issues

```bash
# Must be run as regular user, not root
su - ubuntu

# Reload NVM
source ~/.nvm/nvm.sh

# Verify NVM installation
nvm --version

# List installed versions
nvm list

# Reinstall Node
nvm install node
nvm use node

# Check environment
echo $NVM_DIR
which node
which npm
```

### PM2 Not Working After Reboot

```bash
# Check PM2 service status
sudo systemctl status pm2-ubuntu

# If not exists, reconfigure startup
su - ubuntu
pm2 startup systemd
# Copy and run the command it outputs as root

# Save process list
pm2 save

# Verify
pm2 list
```

### Supervisor Not Running

```bash
# Check service status
sudo systemctl status supervisor

# Check logs
sudo tail -f /var/log/supervisor/supervisord.log

# Reload configuration
sudo supervisorctl reread
sudo supervisorctl update

# Manually start
sudo systemctl start supervisor
```

### Permission Issues

```bash
# Fix web directory permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Fix PHP-FPM socket permissions (if needed)
sudo chown www-data:www-data /var/run/php/php8.2-fpm.sock

# Fix Laravel storage permissions
sudo chmod -R 775 /var/www/myapp/storage
sudo chmod -R 775 /var/www/myapp/bootstrap/cache
```

### Port Already in Use

```bash
# Check what's using port 80
sudo lsof -i :80
sudo netstat -tulpn | grep :80

# If Apache is installed
sudo systemctl stop apache2
sudo systemctl disable apache2
```

## 📝 Version Information

- **Script Version**: 1.0
- **Supported Ubuntu**: 20.04 LTS, 22.04 LTS, 24.04 LTS
- **PHP Versions**: 8.1, 8.2, 8.3 (from Ondřej PPA)
- **MySQL Version**: 8.0 (from Ubuntu repos)
- **Node.js Versions**: LTS, 18.x, 20.x, 22.x
- **NVM Version**: 0.39.7
- **Package Manager**: APT

## 📄 File Locations Reference

| Service | Config | Logs | Data |
|---------|--------|------|------|
| Nginx | `/etc/nginx/` | `/var/log/nginx/` | `/var/www/html` |
| PHP 8.2 | `/etc/php/8.2/` | `/var/log/php8.2-fpm.log` | - |
| MySQL | `/etc/mysql/` | `/var/log/mysql/` | `/var/lib/mysql` |
| Supervisor | `/etc/supervisor/` | `/var/log/supervisor/` | - |
| NVM | `~/.nvm` | - | `~/.nvm/versions/node/` |

## 🔄 Ubuntu Version Differences

### Ubuntu 20.04 (Focal)

- PHP 8.x requires Ondřej PPA
- MySQL 8.0 available
- Systemd 245

### Ubuntu 22.04 (Jammy)

- PHP 8.1 in main repos, 8.2/8.3 via PPA
- MySQL 8.0 available
- Systemd 249

### Ubuntu 24.04 (Noble)

- PHP 8.3 in main repos
- MySQL 8.0 available
- Systemd 255

**Note:** Script uses Ondřej PPA for all versions to ensure consistent PHP version availability.

## 🤝 Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review service logs: `sudo journalctl -xe`
3. Check UFW firewall: `sudo ufw status`
4. Verify Ubuntu version compatibility

## ⚠️ Important Notes

1. **Root Access**: Always run installation script with `sudo`
2. **User Context**: NVM/Node commands run as regular user, not root
3. **Passwords**: Use strong passwords (min 8 characters) for MySQL
4. **Backup**: Always backup data before running uninstall script
5. **Testing**: Test on non-production environments first
6. **Updates**: Keep services updated: `sudo apt update && sudo apt upgrade`
7. **Firewall**: Configure UFW before exposing server to internet
8. **SSL**: Use Let's Encrypt (certbot) for production HTTPS

## 🔐 Security Best Practices

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Enable automatic security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades

# Configure UFW
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https

# Disable root login via SSH
sudo vim /etc/ssh/sshd_config
# Set: PermitRootLogin no
sudo systemctl restart sshd

# Install fail2ban
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## 🔄 Service Management Quick Reference

```bash
# Check all services status
sudo systemctl status nginx php8.2-fpm mysql supervisor

# Restart all services
sudo systemctl restart nginx php8.2-fpm mysql supervisor

# Enable all services on boot
sudo systemctl enable nginx php8.2-fpm mysql supervisor

# View all logs
sudo journalctl -xe

# Follow specific service log
sudo journalctl -fu nginx
```

## 📚 Additional Resources

- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [PHP Documentation](https://www.php.net/docs.php)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Supervisor Documentation](http://supervisord.org/)
- [NVM Documentation](https://github.com/nvm-sh/nvm)
- [PM2 Documentation](https://pm2.keymetrics.io/)

---

**Last Updated**: 2025-10-01
**Maintained By**: DevOps Team
