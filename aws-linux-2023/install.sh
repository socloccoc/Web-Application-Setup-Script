#!/bin/bash

# AWS Linux 2023 - Web Application Setup Script
# This script installs PHP, Nginx, MySQL, Supervisor, NVM, Node, Yarn, PM2

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

# Variables
INSTALL_PHP=false
INSTALL_NGINX=false
INSTALL_MYSQL=false
INSTALL_SUPERVISOR=false
INSTALL_NVM=false
MYSQL_ROOT_PASSWORD=""
MYSQL_DB_NAME=""
MYSQL_DB_USER=""
MYSQL_DB_PASSWORD=""

# Function to display menu
show_menu() {
    clear
    echo "=========================================="
    echo "  AWS Linux 2023 - Web App Setup"
    echo "=========================================="
    echo ""
    echo "Select services to install:"
    echo ""
    echo "1. PHP + Nginx + PHP-FPM + Composer"
    echo "2. MySQL"
    echo "3. Supervisor"
    echo "4. NVM + Node + Yarn + PM2"
    echo "5. Install All"
    echo "6. Start Installation"
    echo "0. Exit"
    echo ""
}

# Function to toggle selection
toggle_service() {
    case $1 in
        1)
            INSTALL_PHP=true
            INSTALL_NGINX=true
            log_info "Selected: PHP + Nginx + PHP-FPM + Composer"
            ;;
        2)
            INSTALL_MYSQL=true
            log_info "Selected: MySQL"
            ;;
        3)
            INSTALL_SUPERVISOR=true
            log_info "Selected: Supervisor"
            ;;
        4)
            INSTALL_NVM=true
            log_info "Selected: NVM + Node + Yarn + PM2"
            ;;
        5)
            INSTALL_PHP=true
            INSTALL_NGINX=true
            INSTALL_MYSQL=true
            INSTALL_SUPERVISOR=true
            INSTALL_NVM=true
            log_info "Selected: All services"
            ;;
    esac
}

# Interactive menu
while true; do
    show_menu

    echo "Current selections:"
    [ "$INSTALL_PHP" = true ] && echo "   PHP + Nginx + PHP-FPM + Composer"
    [ "$INSTALL_MYSQL" = true ] && echo "   MySQL"
    [ "$INSTALL_SUPERVISOR" = true ] && echo "   Supervisor"
    [ "$INSTALL_NVM" = true ] && echo "   NVM + Node + Yarn + PM2"
    echo ""

    read -p "Enter your choice: " choice

    case $choice in
        0)
            log_info "Exiting..."
            exit 0
            ;;
        1|2|3|4|5)
            toggle_service $choice
            sleep 1
            ;;
        6)
            break
            ;;
        *)
            log_error "Invalid option"
            sleep 1
            ;;
    esac
done

# Check if any service is selected
if [ "$INSTALL_PHP" = false ] && [ "$INSTALL_MYSQL" = false ] && [ "$INSTALL_SUPERVISOR" = false ] && [ "$INSTALL_NVM" = false ]; then
    log_error "No services selected. Exiting..."
    exit 1
fi

# MySQL configuration if selected
if [ "$INSTALL_MYSQL" = true ]; then
    echo ""
    log_info "MySQL Configuration"
    read -sp "Enter MySQL root password: " MYSQL_ROOT_PASSWORD
    echo ""
    read -sp "Confirm MySQL root password: " MYSQL_ROOT_PASSWORD_CONFIRM
    echo ""

    if [ "$MYSQL_ROOT_PASSWORD" != "$MYSQL_ROOT_PASSWORD_CONFIRM" ]; then
        log_error "Passwords do not match"
        exit 1
    fi

    read -p "Enter database name: " MYSQL_DB_NAME
    read -p "Enter database user: " MYSQL_DB_USER
    read -sp "Enter database user password: " MYSQL_DB_PASSWORD
    echo ""
fi

log_info "Starting installation..."

# Update system
log_info "Updating system packages..."
dnf update -y

# Install PHP + Nginx + PHP-FPM + Composer
if [ "$INSTALL_PHP" = true ]; then
    log_info "Installing PHP, Nginx, PHP-FPM, and Composer..."

    # Install PHP 8.2 and extensions
    dnf install -y php8.2 php8.2-fpm php8.2-cli php8.2-mysqlnd php8.2-pdo \
        php8.2-mbstring php8.2-xml php8.2-gd php8.2-curl php8.2-zip \
        php8.2-opcache php8.2-intl php8.2-bcmath

    # Install Nginx
    dnf install -y nginx

    # Configure PHP-FPM
    sed -i 's/user = apache/user = nginx/' /etc/php-fpm.d/www.conf
    sed -i 's/group = apache/group = nginx/' /etc/php-fpm.d/www.conf

    # Start and enable services
    systemctl start php-fpm
    systemctl enable php-fpm
    systemctl start nginx
    systemctl enable nginx

    # Install Composer
    log_info "Installing Composer..."
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    chmod +x /usr/local/bin/composer

    log_info "PHP $(php -v | head -n 1 | cut -d ' ' -f 2) installed"
    log_info "Nginx $(nginx -v 2>&1 | cut -d '/' -f 2) installed"
    log_info "Composer $(composer --version | cut -d ' ' -f 3) installed"
fi

# Install MySQL
if [ "$INSTALL_MYSQL" = true ]; then
    log_info "Installing MySQL..."

    # Install MySQL 8.0
    dnf install -y mysql-community-server

    # Start MySQL
    systemctl start mysqld
    systemctl enable mysqld

    # Secure MySQL installation
    log_info "Configuring MySQL..."

    # Set root password
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"

    # Remove anonymous users
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.user WHERE User='';"

    # Disallow root login remotely
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"

    # Remove test database
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS test;"
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"

    # Create database and user
    if [ -n "$MYSQL_DB_NAME" ] && [ -n "$MYSQL_DB_USER" ] && [ -n "$MYSQL_DB_PASSWORD" ]; then
        log_info "Creating database: $MYSQL_DB_NAME"
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MYSQL_DB_USER}'@'localhost' IDENTIFIED BY '${MYSQL_DB_PASSWORD}';"
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON ${MYSQL_DB_NAME}.* TO '${MYSQL_DB_USER}'@'localhost';"
        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
        log_info "Database and user created successfully"
    fi

    log_info "MySQL $(mysql --version | cut -d ' ' -f 6 | cut -d ',' -f 1) installed"
fi

# Install Supervisor
if [ "$INSTALL_SUPERVISOR" = true ]; then
    log_info "Installing Supervisor..."

    dnf install -y supervisor

    # Create log directory
    mkdir -p /var/log/supervisor

    # Start and enable Supervisor
    systemctl start supervisord
    systemctl enable supervisord

    log_info "Supervisor $(supervisord -v) installed"
fi

# Install NVM + Node + Yarn + PM2
if [ "$INSTALL_NVM" = true ]; then
    log_info "Installing NVM, Node, Yarn, and PM2..."

    # Get the actual user (not root)
    ACTUAL_USER=${SUDO_USER:-$USER}
    ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)

    # Install NVM
    log_info "Installing NVM..."
    su - $ACTUAL_USER -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"

    # Load NVM and install Node LTS
    log_info "Installing Node.js LTS..."
    su - $ACTUAL_USER -c "export NVM_DIR=\"$ACTUAL_HOME/.nvm\" && [ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\" && nvm install --lts && nvm use --lts"

    # Install Yarn
    log_info "Installing Yarn..."
    su - $ACTUAL_USER -c "export NVM_DIR=\"$ACTUAL_HOME/.nvm\" && [ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\" && npm install -g yarn"

    # Install PM2
    log_info "Installing PM2..."
    su - $ACTUAL_USER -c "export NVM_DIR=\"$ACTUAL_HOME/.nvm\" && [ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\" && npm install -g pm2"

    # Setup PM2 to start on boot
    log_info "Setting up PM2 startup..."
    su - $ACTUAL_USER -c "export NVM_DIR=\"$ACTUAL_HOME/.nvm\" && [ -s \"$NVM_DIR/nvm.sh\" ] && . \"$NVM_DIR/nvm.sh\" && pm2 startup systemd -u $ACTUAL_USER --hp $ACTUAL_HOME" | grep -v "^export NVM_DIR=" | grep "sudo" | sh

    log_info "NVM, Node.js, Yarn, and PM2 installed for user: $ACTUAL_USER"
fi

# Summary
echo ""
echo "=========================================="
log_info "Installation completed successfully!"
echo "=========================================="
echo ""

if [ "$INSTALL_PHP" = true ]; then
    echo "PHP + Nginx + PHP-FPM + Composer:"
    echo "  - PHP version: $(php -v | head -n 1 | cut -d ' ' -f 2)"
    echo "  - Nginx config: /etc/nginx/nginx.conf"
    echo "  - PHP-FPM config: /etc/php-fpm.d/www.conf"
    echo "  - Web root: /usr/share/nginx/html"
fi

if [ "$INSTALL_MYSQL" = true ]; then
    echo ""
    echo "MySQL:"
    echo "  - Version: $(mysql --version | cut -d ' ' -f 6 | cut -d ',' -f 1)"
    echo "  - Root password: [hidden]"
    if [ -n "$MYSQL_DB_NAME" ]; then
        echo "  - Database: $MYSQL_DB_NAME"
        echo "  - User: $MYSQL_DB_USER"
    fi
fi

if [ "$INSTALL_SUPERVISOR" = true ]; then
    echo ""
    echo "Supervisor:"
    echo "  - Version: $(supervisord -v)"
    echo "  - Config: /etc/supervisord.conf"
    echo "  - Program configs: /etc/supervisord.d/"
fi

if [ "$INSTALL_NVM" = true ]; then
    echo ""
    echo "NVM + Node + Yarn + PM2:"
    echo "  - Installed for user: $ACTUAL_USER"
    echo "  - To use NVM: source ~/.nvm/nvm.sh"
    echo "  - Node version: $(su - $ACTUAL_USER -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && node --version')"
    echo "  - Yarn version: $(su - $ACTUAL_USER -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && yarn --version')"
    echo "  - PM2 version: $(su - $ACTUAL_USER -c 'export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && pm2 --version')"
fi

echo ""
log_info "All services are running and enabled to start on boot"
echo ""
