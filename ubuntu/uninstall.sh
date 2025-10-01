#!/bin/bash

# Ubuntu - Uninstall Script
# This script removes all services installed by install.sh

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
echo "  - Redis"
echo "  - Let's Encrypt SSL (Certbot)"
echo "  - Prometheus"
echo "  - Grafana"
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

# Detect installed PHP version
PHP_VERSION=""
for version in 8.3 8.2 8.1; do
    if command -v php${version} &> /dev/null; then
        PHP_VERSION=$version
        break
    fi
done

# Stop and remove PM2 processes
if command -v pm2 &> /dev/null || su - $ACTUAL_USER -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && command -v pm2' &> /dev/null; then
    log_info "Removing PM2 processes..."
    su - $ACTUAL_USER bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && pm2 kill' 2>/dev/null || true
    su - $ACTUAL_USER bash -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && pm2 unstartup systemd' 2>/dev/null || true

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
if systemctl is-active --quiet supervisor 2>/dev/null; then
    log_info "Stopping Supervisor..."
    systemctl stop supervisor
    systemctl disable supervisor
fi

if command -v supervisord &> /dev/null; then
    log_info "Removing Supervisor..."

    # Uninstall supervisor
    apt-get remove -y supervisor
    apt-get purge -y supervisor

    # Remove config and log directories
    rm -rf /var/log/supervisor
    rm -rf /etc/supervisor
    rm -rf /var/run/supervisor.sock
fi

# Stop and remove MySQL
if systemctl is-active --quiet mysql 2>/dev/null; then
    log_info "Stopping MySQL..."
    systemctl stop mysql
    systemctl disable mysql
fi

if command -v mysql &> /dev/null; then
    log_info "Removing MySQL..."

    # Stop MySQL
    systemctl stop mysql 2>/dev/null || true

    # Remove MySQL packages
    apt-get remove -y mysql-server mysql-client mysql-common
    apt-get purge -y mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-*

    # Remove MySQL data and configs
    rm -rf /var/lib/mysql
    rm -rf /etc/mysql
    rm -rf /var/log/mysql
    rm -rf /var/log/mysql.*

    # Remove MySQL user and group
    userdel mysql 2>/dev/null || true
    groupdel mysql 2>/dev/null || true
fi

# Stop and remove PHP-FPM
if [ -n "$PHP_VERSION" ]; then
    if systemctl is-active --quiet php${PHP_VERSION}-fpm 2>/dev/null; then
        log_info "Stopping PHP-FPM..."
        systemctl stop php${PHP_VERSION}-fpm
        systemctl disable php${PHP_VERSION}-fpm
    fi
fi

# Remove Composer
if [ -f "/usr/local/bin/composer" ]; then
    log_info "Removing Composer..."
    rm -f /usr/local/bin/composer
fi

# Remove PHP
if [ -n "$PHP_VERSION" ]; then
    log_info "Removing PHP ${PHP_VERSION}..."

    # Remove all PHP packages
    apt-get remove -y php${PHP_VERSION}*
    apt-get purge -y php${PHP_VERSION}*

    # Remove PHP config directories
    rm -rf /etc/php/${PHP_VERSION}
    rm -rf /var/log/php${PHP_VERSION}-fpm
    rm -rf /var/lib/php

    # Remove Ondřej PPA
    log_info "Removing Ondřej PHP PPA..."
    add-apt-repository -y --remove ppa:ondrej/php 2>/dev/null || true
fi

# Stop and remove Nginx
if systemctl is-active --quiet nginx 2>/dev/null; then
    log_info "Stopping Nginx..."
    systemctl stop nginx
    systemctl disable nginx
fi

if command -v nginx &> /dev/null; then
    log_info "Removing Nginx..."

    # Remove Nginx package
    apt-get remove -y nginx nginx-common nginx-core
    apt-get purge -y nginx nginx-common nginx-core

    # Ask before removing web files
    read -p "Remove Nginx web files (/var/www/html)? (yes/no): " remove_web
    if [ "$remove_web" = "yes" ]; then
        rm -rf /var/www
    fi

    rm -rf /etc/nginx
    rm -rf /var/log/nginx

    # Remove nginx user and group
    userdel www-data 2>/dev/null || true
    groupdel www-data 2>/dev/null || true
fi

# Stop and remove Redis
if systemctl is-active --quiet redis-server 2>/dev/null; then
    log_info "Stopping Redis..."
    systemctl stop redis-server
    systemctl disable redis-server
fi

if command -v redis-cli &> /dev/null; then
    log_info "Removing Redis..."
    apt-get remove -y redis-server redis-tools
    apt-get purge -y redis-server redis-tools

    # Remove Redis data and configs
    rm -rf /etc/redis
    rm -rf /var/lib/redis
    rm -rf /var/log/redis
fi

# Remove Certbot (Let's Encrypt)
if command -v certbot &> /dev/null; then
    log_info "Removing Certbot..."

    # Stop renewal timer
    systemctl stop certbot.timer 2>/dev/null || true
    systemctl disable certbot.timer 2>/dev/null || true

    # Remove certbot packages
    apt-get remove -y certbot python3-certbot-nginx
    apt-get purge -y certbot python3-certbot-nginx

    # Ask before removing SSL certificates
    read -p "Remove all SSL certificates? (yes/no): " remove_certs
    if [ "$remove_certs" = "yes" ]; then
        rm -rf /etc/letsencrypt
        rm -rf /var/lib/letsencrypt
        rm -rf /var/log/letsencrypt
        log_info "SSL certificates removed"
    else
        log_warn "SSL certificates kept at /etc/letsencrypt"
    fi
fi

# Stop and remove Prometheus
if systemctl is-active --quiet prometheus 2>/dev/null; then
    log_info "Stopping Prometheus..."
    systemctl stop prometheus
    systemctl disable prometheus
fi

if command -v prometheus &> /dev/null || [ -f "/usr/local/bin/prometheus" ]; then
    log_info "Removing Prometheus..."

    # Stop service
    systemctl stop prometheus 2>/dev/null || true
    systemctl disable prometheus 2>/dev/null || true

    # Remove systemd service
    rm -f /etc/systemd/system/prometheus.service
    systemctl daemon-reload

    # Remove binaries
    rm -f /usr/local/bin/prometheus
    rm -f /usr/local/bin/promtool

    # Remove config and data directories
    rm -rf /etc/prometheus
    rm -rf /var/lib/prometheus

    # Remove user and group
    userdel prometheus 2>/dev/null || true
    groupdel prometheus 2>/dev/null || true

    log_info "Prometheus removed"
fi

# Stop and remove Node Exporter
if systemctl is-active --quiet node_exporter 2>/dev/null; then
    log_info "Stopping Node Exporter..."
    systemctl stop node_exporter
    systemctl disable node_exporter
fi

if command -v node_exporter &> /dev/null || [ -f "/usr/local/bin/node_exporter" ]; then
    log_info "Removing Node Exporter..."

    # Stop service
    systemctl stop node_exporter 2>/dev/null || true
    systemctl disable node_exporter 2>/dev/null || true

    # Remove systemd service
    rm -f /etc/systemd/system/node_exporter.service
    systemctl daemon-reload

    # Remove binary
    rm -f /usr/local/bin/node_exporter

    # Remove user and group
    userdel node_exporter 2>/dev/null || true
    groupdel node_exporter 2>/dev/null || true

    log_info "Node Exporter removed"
fi

# Stop and remove Grafana
if systemctl is-active --quiet grafana-server 2>/dev/null; then
    log_info "Stopping Grafana..."
    systemctl stop grafana-server
    systemctl disable grafana-server
fi

if command -v grafana-server &> /dev/null; then
    log_info "Removing Grafana..."

    # Remove Grafana package
    apt-get remove -y grafana
    apt-get purge -y grafana

    # Remove repository
    rm -f /etc/apt/sources.list.d/grafana.list

    # Remove config and data directories
    rm -rf /etc/grafana
    rm -rf /var/lib/grafana
    rm -rf /var/log/grafana

    log_info "Grafana removed"
fi

# Clean up APT
log_info "Cleaning up package cache..."
apt-get autoremove -y
apt-get autoclean
apt-get clean

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

if [ -d "/etc/supervisor" ]; then
    log_warn "Supervisor config directory still exists: /etc/supervisor"
    remaining=true
fi

if [ -d "/var/www" ]; then
    log_warn "Web directory still exists: /var/www"
    remaining=true
fi

if [ -d "/etc/redis" ]; then
    log_warn "Redis config directory still exists: /etc/redis"
    remaining=true
fi

if [ -d "/etc/letsencrypt" ]; then
    log_warn "SSL certificates still exist: /etc/letsencrypt"
    remaining=true
fi

if [ -d "/etc/prometheus" ]; then
    log_warn "Prometheus config directory still exists: /etc/prometheus"
    remaining=true
fi

if [ -d "/var/lib/prometheus" ]; then
    log_warn "Prometheus data directory still exists: /var/lib/prometheus"
    remaining=true
fi

if [ -d "/etc/grafana" ]; then
    log_warn "Grafana config directory still exists: /etc/grafana"
    remaining=true
fi

if [ -d "/var/lib/grafana" ]; then
    log_warn "Grafana data directory still exists: /var/lib/grafana"
    remaining=true
fi

if [ "$remaining" = false ]; then
    log_info "No remaining files found"
fi

echo ""
log_info "Please reboot the system if you encounter any issues"
echo ""
