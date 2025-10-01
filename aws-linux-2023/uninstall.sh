#!/bin/bash

# AWS Linux 2023 - Uninstall Script
# This script removes all services installed by aws-linux-2023.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Warning message
echo "=========================================="
log_warn "WARNING: This will remove all installed services!"
echo "=========================================="
echo ""
echo "Services that will be removed:"
echo "  - PHP + Nginx + PHP-FPM + Composer"
echo "  - MySQL (including all databases)"
echo "  - Supervisor"
echo "  - NVM + Node + Yarn + PM2"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    log_info "Uninstall cancelled"
    exit 0
fi

echo ""
log_info "Starting uninstallation..."

# Get the actual user (not root)
ACTUAL_USER=${SUDO_USER:-$USER}
ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)

# Stop and remove PM2 processes
if command -v pm2 &> /dev/null || su - $ACTUAL_USER -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && command -v pm2' &> /dev/null; then
    log_info "Removing PM2 processes..."
    su - $ACTUAL_USER -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && pm2 kill' 2>/dev/null || true
    su - $ACTUAL_USER -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && pm2 unstartup systemd' 2>/dev/null || true

    # Remove PM2 systemd service if exists
    if [ -f "/etc/systemd/system/pm2-$ACTUAL_USER.service" ]; then
        systemctl stop "pm2-$ACTUAL_USER" 2>/dev/null || true
        systemctl disable "pm2-$ACTUAL_USER" 2>/dev/null || true
        rm -f "/etc/systemd/system/pm2-$ACTUAL_USER.service"
        systemctl daemon-reload
    fi
fi

# Remove NVM
if [ -d "$ACTUAL_HOME/.nvm" ]; then
    log_info "Removing NVM..."
    rm -rf "$ACTUAL_HOME/.nvm"

    # Remove NVM from shell configs
    sed -i '/NVM_DIR/d' "$ACTUAL_HOME/.bashrc" 2>/dev/null || true
    sed -i '/nvm.sh/d' "$ACTUAL_HOME/.bashrc" 2>/dev/null || true
    sed -i '/bash_completion/d' "$ACTUAL_HOME/.bashrc" 2>/dev/null || true

    if [ -f "$ACTUAL_HOME/.bash_profile" ]; then
        sed -i '/NVM_DIR/d' "$ACTUAL_HOME/.bash_profile" 2>/dev/null || true
        sed -i '/nvm.sh/d' "$ACTUAL_HOME/.bash_profile" 2>/dev/null || true
        sed -i '/bash_completion/d' "$ACTUAL_HOME/.bash_profile" 2>/dev/null || true
    fi

    if [ -f "$ACTUAL_HOME/.zshrc" ]; then
        sed -i '/NVM_DIR/d' "$ACTUAL_HOME/.zshrc" 2>/dev/null || true
        sed -i '/nvm.sh/d' "$ACTUAL_HOME/.zshrc" 2>/dev/null || true
        sed -i '/bash_completion/d' "$ACTUAL_HOME/.zshrc" 2>/dev/null || true
    fi

    # Remove global npm packages cache
    rm -rf "$ACTUAL_HOME/.npm" 2>/dev/null || true
    rm -rf "$ACTUAL_HOME/.yarn" 2>/dev/null || true
    rm -rf "$ACTUAL_HOME/.config/yarn" 2>/dev/null || true
    rm -rf "$ACTUAL_HOME/.pm2" 2>/dev/null || true
fi

# Stop and remove Supervisor
if systemctl is-active --quiet supervisord 2>/dev/null; then
    log_info "Stopping Supervisor..."
    systemctl stop supervisord
    systemctl disable supervisord
fi

if command -v supervisord &> /dev/null; then
    log_info "Removing Supervisor..."
    dnf remove -y supervisor
    rm -rf /var/log/supervisor
    rm -rf /etc/supervisord.conf
    rm -rf /etc/supervisord.d
fi

# Stop and remove MySQL
if systemctl is-active --quiet mysqld 2>/dev/null; then
    log_info "Stopping MySQL..."
    systemctl stop mysqld
    systemctl disable mysqld
fi

if command -v mysql &> /dev/null; then
    log_info "Removing MySQL..."
    dnf remove -y mysql-community-server mysql-community-client mysql-community-common mysql-community-libs mysql-community-libs-compat

    # Remove MySQL repository
    dnf remove -y mysql80-community-release 2>/dev/null || true
    rm -rf /etc/yum.repos.d/mysql-community*.repo

    # Remove MySQL data and configs
    rm -rf /var/lib/mysql
    rm -rf /etc/my.cnf
    rm -rf /etc/my.cnf.d
    rm -rf /var/log/mysqld.log

    # Remove MySQL user and group
    userdel mysql 2>/dev/null || true
    groupdel mysql 2>/dev/null || true
fi

# Stop and remove PHP-FPM
if systemctl is-active --quiet php-fpm 2>/dev/null; then
    log_info "Stopping PHP-FPM..."
    systemctl stop php-fpm
    systemctl disable php-fpm
fi

# Remove Composer
if [ -f "/usr/local/bin/composer" ]; then
    log_info "Removing Composer..."
    rm -f /usr/local/bin/composer
fi

# Remove PHP
if command -v php &> /dev/null; then
    log_info "Removing PHP..."
    dnf remove -y php8.2 php8.2-* php-*
    rm -rf /etc/php.ini
    rm -rf /etc/php-fpm.d
    rm -rf /etc/php.d
    rm -rf /var/log/php-fpm
fi

# Stop and remove Nginx
if systemctl is-active --quiet nginx 2>/dev/null; then
    log_info "Stopping Nginx..."
    systemctl stop nginx
    systemctl disable nginx
fi

if command -v nginx &> /dev/null; then
    log_info "Removing Nginx..."
    dnf remove -y nginx

    # Ask before removing web files
    read -p "Remove Nginx web files (/usr/share/nginx/html)? (yes/no): " remove_web
    if [ "$remove_web" = "yes" ]; then
        rm -rf /usr/share/nginx
    fi

    rm -rf /etc/nginx
    rm -rf /var/log/nginx

    # Remove nginx user and group
    userdel nginx 2>/dev/null || true
    groupdel nginx 2>/dev/null || true
fi

# Clean up DNF cache
log_info "Cleaning up package cache..."
dnf autoremove -y
dnf clean all

# Summary
echo ""
echo "=========================================="
log_info "Uninstallation completed!"
echo "=========================================="
echo ""
log_info "All services have been removed"
echo ""

# List remaining files (if any)
log_info "Checking for remaining files..."
remaining=false

if [ -d "$ACTUAL_HOME/.nvm" ]; then
    log_warn "NVM directory still exists: $ACTUAL_HOME/.nvm"
    remaining=true
fi

if [ -d "/etc/nginx" ]; then
    log_warn "Nginx config directory still exists: /etc/nginx"
    remaining=true
fi

if [ -d "/var/lib/mysql" ]; then
    log_warn "MySQL data directory still exists: /var/lib/mysql"
    remaining=true
fi

if [ -d "/etc/supervisord.d" ]; then
    log_warn "Supervisor config directory still exists: /etc/supervisord.d"
    remaining=true
fi

if [ "$remaining" = false ]; then
    log_info "No remaining files found"
fi

echo ""
log_info "Please reboot the system if you encounter any issues"
echo ""
