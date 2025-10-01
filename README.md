# Init Scripts - Automated Server Setup

Automated installation scripts for setting up complete web application stacks on different Linux distributions.

## 📋 Supported Distributions

| Distribution | Status | Directory | Documentation |
|--------------|--------|-----------|---------------|
| AWS Linux 2023 | ✅ Ready | [aws-linux-2023/](./aws-linux-2023/) | [README](./aws-linux-2023/README.md) |
| Ubuntu 20.04/22.04/24.04 | ✅ Ready | [ubuntu/](./ubuntu/) | [README](./ubuntu/README.md) |

## 🎯 Purpose

These scripts automate the installation and configuration of common web application stacks, including:

- **Web Servers**: Nginx
- **Languages**: PHP (multiple versions), Node.js (via NVM)
- **Databases**: MySQL
- **Caching**: Redis
- **Process Managers**: Supervisor, PM2
- **Package Managers**: Composer, Yarn, npm
- **SSL/TLS**: Let's Encrypt (Certbot)
- **Monitoring**: Prometheus, Grafana, Node Exporter

## 🚀 Quick Start

### AWS Linux 2023

```bash
cd aws-linux-2023
sudo ./install.sh
```

**Features:**
- Interactive menu-driven installation
- PHP 8.1/8.2/8.3 selection
- Node.js LTS/18/20/22 selection
- MySQL 8.0 with auto database creation
- Redis caching server
- Let's Encrypt SSL automation
- Supervisor process control
- Complete uninstall script

[📖 Full AWS Linux 2023 Documentation](./aws-linux-2023/README.md)

### Ubuntu

```bash
cd ubuntu
sudo ./install.sh
```

**Features:**
- Support for Ubuntu 20.04, 22.04, 24.04 LTS
- Interactive menu-driven installation
- PHP 8.1/8.2/8.3 from Ondřej PPA
- Node.js LTS/18/20/22 selection
- MySQL 8.0 with auto database creation
- Redis caching server
- Let's Encrypt SSL automation
- Prometheus + Grafana + Node Exporter monitoring
- Supervisor process control
- Complete uninstall script

[📖 Full Ubuntu Documentation](./ubuntu/README.md)

## 📦 Installation Options

All scripts provide interactive menus to install:

1. **PHP Stack**: PHP + Nginx + PHP-FPM + Composer
2. **Database**: MySQL with user creation
3. **Process Control**: Supervisor
4. **Node.js Stack**: Nginx + NVM + Node + Yarn + PM2
5. **Caching**: Redis
6. **SSL/TLS**: Let's Encrypt (Certbot)
7. **Monitoring**: Prometheus + Grafana + Node Exporter (Ubuntu only)
8. **All Services**: Complete stack installation

## 🔧 Common Features

### Interactive Installation
- Choose which services to install
- Select software versions
- Configure databases and users
- Set passwords securely

### Automated Configuration
- Services configured and started automatically
- Systemd integration
- Firewall rules (when applicable)
- User permissions setup

### Uninstall Support
- Complete removal of installed services
- Clean package cache
- Remove configuration files
- Optional data deletion

## 📖 Documentation Structure

Each distribution has its own detailed README:

```
init-scrips/
├── README.md                          # This file (overview)
├── aws-linux-2023/
│   ├── README.md                      # AWS Linux specific guide
│   ├── install.sh                     # Installation script
│   └── uninstall.sh                   # Uninstall script
└── ubuntu/
    ├── README.md                      # Ubuntu specific guide
    ├── install.sh                     # Installation script
    └── uninstall.sh                   # Uninstall script
```

## 🔐 Security Considerations

### Before Running Scripts

1. **Review the code**: Always review scripts before running with root privileges
2. **Test environment**: Test on non-production servers first
3. **Backup data**: Backup important data before installation
4. **Update system**: Run system updates before installation

### During Installation

- Use strong passwords for databases
- Note down credentials securely
- Review firewall configurations
- Check service permissions

### After Installation

```bash
# Update packages
sudo dnf update -y  # AWS Linux
sudo apt update && sudo apt upgrade -y  # Ubuntu

# Run MySQL security script
sudo mysql_secure_installation

# Configure firewall
sudo firewall-cmd --list-all  # AWS Linux
sudo ufw status  # Ubuntu

# Check service status
sudo systemctl status nginx php-fpm mysqld supervisord
```

## 🎨 Usage Examples

### Example 1: PHP Web Application

```bash
# Install PHP stack
sudo ./install.sh
# Select: Option 1 (PHP + Nginx + PHP-FPM + Composer)
# Select: PHP 8.2

# Deploy application
sudo mkdir -p /var/www/myapp
sudo chown -R nginx:nginx /var/www/myapp
cd /var/www/myapp
composer install

# Configure Nginx site
sudo vim /etc/nginx/conf.d/myapp.conf
sudo nginx -t
sudo systemctl reload nginx
```

### Example 2: Node.js Application

```bash
# Install Node.js stack
sudo ./install.sh
# Select: Option 4 (Nginx + NVM + Node + Yarn + PM2)
# Select: Node.js 20

# Switch to user account
# Deploy application
cd /home/ec2-user/myapp
yarn install
pm2 start app.js --name myapp
pm2 startup
pm2 save

# Configure Nginx reverse proxy
sudo vim /etc/nginx/conf.d/myapp.conf
sudo systemctl reload nginx
```

### Example 3: Full Stack (PHP + Node.js + MySQL)

```bash
# Install all services
sudo ./install.sh
# Select: Option 8 (All services)
# Configure: PHP 8.2, Node.js 20, MySQL database

# PHP backend
cd /var/www/api
composer install

# Node.js frontend
su - ec2-user
cd /home/ec2-user/frontend
yarn install
pm2 start npm --name frontend -- start

# Database
mysql -u root -p
# Import schema and data
```

### Example 4: Monitoring Stack (Ubuntu)

```bash
# Install monitoring tools
sudo ./install.sh
# Select: Option 7 (Prometheus + Grafana + Node Exporter)

# Access dashboards
# Prometheus: http://your-server-ip:9090
# Grafana: http://your-server-ip:3000 (admin/admin)
# Node Exporter: http://your-server-ip:9100/metrics

# Import Grafana dashboards
# 1. Login to Grafana
# 2. Go to Dashboards → Import
# 3. Use dashboard ID: 1860 (Node Exporter Full)
```

## 🐛 Troubleshooting

### Common Issues

**Script Permission Denied**
```bash
chmod +x install.sh
sudo ./install.sh
```

**Service Not Starting**
```bash
# Check status
sudo systemctl status service-name

# Check logs
sudo journalctl -xeu service-name
sudo tail -f /var/log/service-name/error.log
```

**Port Already in Use**
```bash
# Check what's using the port
sudo netstat -tulpn | grep :80
sudo lsof -i :80

# Stop conflicting service
sudo systemctl stop service-name
```

**Package Not Found**
```bash
# Update package cache
sudo dnf clean all && sudo dnf makecache  # AWS Linux
sudo apt update  # Ubuntu

# Check repository configuration
sudo dnf repolist  # AWS Linux
sudo apt-cache policy  # Ubuntu
```

### Getting Help

1. Check distribution-specific README in subdirectories
2. Review service logs: `sudo journalctl -xe`
3. Verify system requirements
4. Check OS version compatibility

## 🔄 Version Matrix

### AWS Linux 2023

| Service | Versions Available |
|---------|-------------------|
| PHP | 8.1, 8.2, 8.3 |
| Node.js | LTS, 18, 20, 22 |
| MySQL | 8.0 |
| Nginx | Latest from repo |
| Redis | 6.x |
| Certbot | Latest from repo |
| Supervisor | Latest from pip3 |

### Ubuntu

| Service | Versions Available |
|---------|-------------------|
| PHP | 8.1, 8.2, 8.3 (via Ondřej PPA) |
| Node.js | LTS, 18, 20, 22 |
| MySQL | 8.0 |
| Nginx | Latest from repo |
| Redis | Latest from repo |
| Certbot | Latest from repo |
| Prometheus | Latest (auto-detect) |
| Grafana | Latest from official repo |
| Node Exporter | Latest (auto-detect) |
| Supervisor | Latest from repo |

## 📁 Project Structure

```
init-scrips/
│
├── README.md                          # Main documentation (this file)
│
├── aws-linux-2023/                    # AWS Linux 2023 scripts
│   ├── README.md                      # Detailed AWS Linux guide
│   ├── install.sh                     # Main installation script
│   └── uninstall.sh                   # Uninstallation script
│
└── ubuntu/                            # Ubuntu scripts
    ├── README.md                      # Detailed Ubuntu guide
    ├── install.sh                     # Main installation script
    └── uninstall.sh                   # Uninstallation script
```

## 🤝 Contributing

### Adding New Distribution Support

1. Create distribution directory: `mkdir distro-name`
2. Copy script template from existing distribution
3. Adapt package manager commands
4. Update service names and paths
5. Test thoroughly on clean installation
6. Create detailed README.md
7. Update main README.md (this file)

### Script Guidelines

- Use bash shebang: `#!/bin/bash`
- Set strict mode: `set -e`
- Include logging functions (INFO, ERROR, WARN)
- Implement interactive menus
- Add version selection where applicable
- Include rollback/uninstall capability
- Test on clean system installations

## ⚠️ Important Notes

1. **Root Required**: All installation scripts require root/sudo access
2. **Clean System**: Best results on fresh OS installations
3. **Internet Access**: Scripts download packages from repositories
4. **Backup First**: Always backup before running uninstall scripts
5. **Test Mode**: Test on development systems before production use
6. **One-Time Run**: Scripts are designed for initial setup, not updates

## 📊 Comparison Table

| Feature | AWS Linux 2023 | Ubuntu 20.04/22.04/24.04 |
|---------|----------------|--------------------------|
| Package Manager | DNF | APT |
| Systemd | ✅ | ✅ |
| PHP Versions | 8.1, 8.2, 8.3 | 8.1, 8.2, 8.3 |
| PHP Source | Amazon repos | Ondřej PPA |
| Node.js | LTS, 18, 20, 22 | LTS, 18, 20, 22 |
| MySQL | 8.0 (Oracle repo) | 8.0 (Ubuntu repo) |
| Redis | ✅ | ✅ |
| Certbot/SSL | ✅ | ✅ |
| Prometheus | ❌ | ✅ |
| Grafana | ❌ | ✅ |
| Node Exporter | ❌ | ✅ |
| Supervisor | pip3 | APT |
| Nginx | ✅ | ✅ |
| Firewall | firewalld | ufw |
| SELinux | ✅ | ❌ |

## 🔮 Roadmap

### ✅ Phase 1 (Completed)
- [x] AWS Linux 2023 support
- [x] Ubuntu 20.04/22.04/24.04 support
- [x] PHP + Nginx + MySQL stack
- [x] Node.js + PM2 stack
- [x] Supervisor support
- [x] Uninstall scripts
- [x] Comprehensive documentation

### 📋 Future Enhancements
- [x] Redis support
- [x] Let's Encrypt SSL automation
- [x] Monitoring tools (Prometheus, Grafana)
- [ ] Backup/restore scripts
- [ ] Docker integration option
- [ ] PostgreSQL option

## 📝 License

These scripts are provided as-is for educational and development purposes.

## 🔗 Related Resources

- [AWS Linux 2023 Documentation](https://docs.aws.amazon.com/linux/)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [PHP Documentation](https://www.php.net/docs.php)
- [Node.js Documentation](https://nodejs.org/docs/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Redis Documentation](https://redis.io/documentation)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

---

**Last Updated**: 2025-10-01
**Maintained By**: DevOps Team
