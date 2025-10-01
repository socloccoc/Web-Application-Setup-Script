#!/bin/bash

# Ubuntu - Service Installation Script
# Supports: Ubuntu 20.04, 22.04, 24.04
# Services: PHP, Nginx, MySQL, Supervisor, NVM, Node, Yarn, PM2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs)
UBUNTU_CODENAME=$(lsb_release -cs)

log_info "Detected Ubuntu ${UBUNTU_VERSION} (${UBUNTU_CODENAME})"

# Verify Ubuntu version
if [[ ! "$UBUNTU_VERSION" =~ ^(20.04|22.04|24.04)$ ]]; then
    log_warn "This script is tested on Ubuntu 20.04, 22.04, and 24.04"
    log_warn "Your version: Ubuntu ${UBUNTU_VERSION}"
    read -p "Continue anyway? (yes/no): " continue_install
    if [ "$continue_install" != "yes" ]; then
        log_info "Installation cancelled"
        exit 0
    fi
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
PHP_VERSION=""
NODE_VERSION=""

# Get the actual user (not root)
ACTUAL_USER=${SUDO_USER:-$USER}
ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)

# Display menu
clear
echo "=========================================="
echo "Ubuntu - Service Installation Script"
echo "=========================================="
echo ""
echo "Select services to install:"
echo "1. PHP + Nginx + PHP-FPM + Composer"
echo "2. MySQL"
echo "3. Supervisor"
echo "4. Nginx + NVM + Node + Yarn + PM2"
echo "5. All of the above"
echo ""
read -p "Enter your choices (comma-separated, e.g., 1,2,3): " choices

# Parse choices
IFS=',' read -ra CHOICE_ARRAY <<< "$choices"
for choice in "${CHOICE_ARRAY[@]}"; do
    choice=$(echo "$choice" | xargs) # Trim whitespace
    case $choice in
        1)
            INSTALL_PHP=true
            INSTALL_NGINX=true
            ;;
        2)
            INSTALL_MYSQL=true
            ;;
        3)
            INSTALL_SUPERVISOR=true
            ;;
        4)
            INSTALL_NGINX=true
            INSTALL_NVM=true
            ;;
        5)
            INSTALL_PHP=true
            INSTALL_NGINX=true
            INSTALL_MYSQL=true
            INSTALL_SUPERVISOR=true
            INSTALL_NVM=true
            ;;
        *)
            log_error "Invalid choice: $choice"
            exit 1
            ;;
    esac
done

# Confirm selections
echo ""
log_info "Selected services:"
[ "$INSTALL_PHP" = true ] && echo "  - PHP + Nginx + PHP-FPM + Composer"
[ "$INSTALL_MYSQL" = true ] && echo "  - MySQL"
[ "$INSTALL_SUPERVISOR" = true ] && echo "  - Supervisor"
[ "$INSTALL_NVM" = true ] && echo "  - NVM + Node + Yarn + PM2"
echo ""
read -p "Continue with installation? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    log_info "Installation cancelled"
    exit 0
fi

# PHP Version Selection
if [ "$INSTALL_PHP" = true ]; then
    echo ""
    log_info "PHP Version Selection"
    echo "Available PHP versions:"
    echo "1. PHP 8.1"
    echo "2. PHP 8.2 (recommended)"
    echo "3. PHP 8.3"
    echo ""
    read -p "Select PHP version (1-3) [default: 2]: " php_choice

    case ${php_choice:-2} in
        1) PHP_VERSION="8.1" ;;
        2) PHP_VERSION="8.2" ;;
        3) PHP_VERSION="8.3" ;;
        *)
            log_error "Invalid PHP version choice"
            exit 1
            ;;
    esac
    log_info "Selected PHP $PHP_VERSION"
fi

# Node Version Selection
if [ "$INSTALL_NVM" = true ]; then
    echo ""
    log_info "Node.js Version Selection"
    echo "Available Node.js versions:"
    echo "1. LTS (Long Term Support - recommended)"
    echo "2. Node.js 18.x"
    echo "3. Node.js 20.x"
    echo "4. Node.js 22.x"
    echo ""
    read -p "Select Node.js version (1-4) [default: 1]: " node_choice

    case ${node_choice:-1} in
        1) NODE_VERSION="--lts" ;;
        2) NODE_VERSION="18" ;;
        3) NODE_VERSION="20" ;;
        4) NODE_VERSION="22" ;;
        *)
            log_error "Invalid Node.js version choice"
            exit 1
            ;;
    esac
    log_info "Selected Node.js version: $NODE_VERSION"
fi

# MySQL Configuration
if [ "$INSTALL_MYSQL" = true ]; then
    echo ""
    log_info "MySQL Configuration"

    while true; do
        read -sp "Enter MySQL root password: " MYSQL_ROOT_PASSWORD
        echo ""
        read -sp "Confirm MySQL root password: " MYSQL_ROOT_PASSWORD_CONFIRM
        echo ""

        if [ "$MYSQL_ROOT_PASSWORD" = "$MYSQL_ROOT_PASSWORD_CONFIRM" ]; then
            if [ ${#MYSQL_ROOT_PASSWORD} -lt 8 ]; then
                log_error "Password must be at least 8 characters"
                continue
            fi
            break
        else
            log_error "Passwords do not match"
        fi
    done

    read -p "Enter database name to create (or leave empty to skip): " MYSQL_DB_NAME

    if [ -n "$MYSQL_DB_NAME" ]; then
        read -p "Enter database user: " MYSQL_DB_USER

        while true; do
            read -sp "Enter database user password: " MYSQL_DB_PASSWORD
            echo ""
            read -sp "Confirm database user password: " MYSQL_DB_PASSWORD_CONFIRM
            echo ""

            if [ "$MYSQL_DB_PASSWORD" = "$MYSQL_DB_PASSWORD_CONFIRM" ]; then
                if [ ${#MYSQL_DB_PASSWORD} -lt 8 ]; then
                    log_error "Password must be at least 8 characters"
                    continue
                fi
                break
            else
                log_error "Passwords do not match"
            fi
        done
    fi
fi

# Start installation
echo ""
echo "=========================================="
log_info "Starting installation..."
echo "=========================================="
echo ""

# Update package list
log_step "Updating package list..."
apt-get update -y

# Install common packages
log_step "Installing common packages..."
apt-get install -y software-properties-common apt-transport-https ca-certificates curl wget gnupg lsb-release

# Install PHP
if [ "$INSTALL_PHP" = true ]; then
    log_step "Installing PHP ${PHP_VERSION}..."

    # Add Ondřej PHP PPA
    log_info "Adding Ondřej PHP PPA repository..."
    add-apt-repository -y ppa:ondrej/php
    apt-get update -y

    # Install PHP and extensions
    log_info "Installing PHP ${PHP_VERSION} and extensions..."
    apt-get install -y \
        php${PHP_VERSION} \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-redis

    # Start and enable PHP-FPM
    systemctl start php${PHP_VERSION}-fpm
    systemctl enable php${PHP_VERSION}-fpm

    log_info "PHP ${PHP_VERSION} installed successfully"
    php -v

    # Install Composer
    log_step "Installing Composer..."
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

    log_info "Composer installed successfully"
    composer --version
fi

# Install Nginx
if [ "$INSTALL_NGINX" = true ]; then
    log_step "Installing Nginx..."

    apt-get install -y nginx

    # Start and enable Nginx
    systemctl start nginx
    systemctl enable nginx

    log_info "Nginx installed successfully"
    nginx -v

    # Configure Nginx for PHP if PHP is installed
    if [ "$INSTALL_PHP" = true ]; then
        log_info "Configuring Nginx for PHP..."

        # Backup default config
        cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

        # Create PHP config
        cat > /etc/nginx/sites-available/default <<NGINX_EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
NGINX_EOF

        # Test and reload Nginx
        nginx -t
        systemctl reload nginx

        # Create test PHP file
        cat > /var/www/html/info.php <<'PHP_EOF'
<?php
phpinfo();
?>
PHP_EOF

        chown -R www-data:www-data /var/www/html

        log_info "Nginx configured for PHP. Test at: http://your-server-ip/info.php"
    fi
fi

# Install MySQL
if [ "$INSTALL_MYSQL" = true ]; then
    log_step "Installing MySQL..."

    # Set debconf selections to avoid interactive prompts
    debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}"

    # Install MySQL server
    DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

    # Start and enable MySQL
    systemctl start mysql
    systemctl enable mysql

    # Wait for MySQL to be ready
    sleep 5

    log_info "Securing MySQL installation..."

    # Secure MySQL installation using expect or direct SQL
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<MYSQL_SECURE_EOF
-- Set root password (in case debconf didn't work)
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Disallow root login remotely
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Reload privilege tables
FLUSH PRIVILEGES;
MYSQL_SECURE_EOF

    log_info "MySQL installed and secured successfully"
    mysql --version

    # Create database and user if specified
    if [ -n "$MYSQL_DB_NAME" ]; then
        log_step "Creating database and user..."

        mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<MYSQL_DB_EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_DB_USER}'@'localhost' IDENTIFIED BY '${MYSQL_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DB_NAME}\`.* TO '${MYSQL_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
MYSQL_DB_EOF

        log_info "Database created: ${MYSQL_DB_NAME}"
        log_info "User created: ${MYSQL_DB_USER}"
        log_info "You can now connect with: mysql -u ${MYSQL_DB_USER} -p ${MYSQL_DB_NAME}"
    fi
fi

# Install Supervisor
if [ "$INSTALL_SUPERVISOR" = true ]; then
    log_step "Installing Supervisor..."

    apt-get install -y supervisor

    # Create config directory if it doesn't exist
    mkdir -p /etc/supervisor/conf.d

    # Start and enable Supervisor
    systemctl start supervisor
    systemctl enable supervisor

    log_info "Supervisor installed successfully"
    supervisorctl version

    log_info "Supervisor config directory: /etc/supervisor/conf.d/"
    log_info "After adding configs, run: sudo supervisorctl reread && sudo supervisorctl update"
fi

# Install NVM, Node, Yarn, PM2
if [ "$INSTALL_NVM" = true ]; then
    log_step "Installing NVM, Node.js, Yarn, and PM2..."

    # Install NVM as the actual user
    log_info "Installing NVM..."
    su - $ACTUAL_USER -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"

    # Wait for NVM to be ready
    sleep 3

    # Load NVM and install Node
    log_info "Installing Node.js ${NODE_VERSION}..."
    echo "This may take a few minutes, please wait..."

    su - $ACTUAL_USER bash -c "
        set -e
        export NVM_DIR=\"$ACTUAL_HOME/.nvm\"
        [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"

        echo \"==> Verifying NVM installation...\"
        nvm --version || { echo \"ERROR: NVM not loaded properly\"; exit 1; }

        echo \"==> Installing Node.js ${NODE_VERSION}...\"
        nvm install ${NODE_VERSION}

        echo \"==> Setting default Node version...\"
        nvm use ${NODE_VERSION}
        nvm alias default ${NODE_VERSION}

        echo \"==> Verifying Node installation...\"
        node --version
        npm --version

        echo \"==> Installing Yarn...\"
        npm install -g yarn
        yarn --version

        echo \"==> Installing PM2...\"
        npm install -g pm2
        pm2 --version

        echo \"==> Setting up PM2 startup script...\"
        pm2 startup systemd -u $ACTUAL_USER --hp $ACTUAL_HOME
    "

    if [ $? -ne 0 ]; then
        log_error "Failed to install Node.js and tools"
        exit 1
    fi

    # Get the startup command from PM2 and execute it
    log_info "Configuring PM2 to start on boot..."
    PM2_STARTUP_CMD=$(su - $ACTUAL_USER bash -c "export NVM_DIR=\"$ACTUAL_HOME/.nvm\"; [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"; pm2 startup systemd -u $ACTUAL_USER --hp $ACTUAL_HOME | grep 'sudo env'")

    if [ -n "$PM2_STARTUP_CMD" ]; then
        eval "$PM2_STARTUP_CMD"
        log_info "PM2 startup configured"
    fi

    log_info "NVM, Node.js, Yarn, and PM2 installed successfully"
    log_info "To use Node.js, switch to user: su - $ACTUAL_USER"
fi

# Summary
echo ""
echo "=========================================="
log_info "Installation completed successfully!"
echo "=========================================="
echo ""

# Display installed services
log_info "Installed services:"
[ "$INSTALL_PHP" = true ] && echo "  ✓ PHP ${PHP_VERSION} + PHP-FPM"
[ "$INSTALL_PHP" = true ] && echo "  ✓ Composer"
[ "$INSTALL_NGINX" = true ] && echo "  ✓ Nginx"
[ "$INSTALL_MYSQL" = true ] && echo "  ✓ MySQL"
[ "$INSTALL_SUPERVISOR" = true ] && echo "  ✓ Supervisor"
[ "$INSTALL_NVM" = true ] && echo "  ✓ NVM + Node.js + Yarn + PM2"

echo ""

# Display credentials
if [ "$INSTALL_MYSQL" = true ]; then
    log_info "MySQL credentials:"
    echo "  Root password: ${MYSQL_ROOT_PASSWORD}"
    if [ -n "$MYSQL_DB_NAME" ]; then
        echo "  Database: ${MYSQL_DB_NAME}"
        echo "  User: ${MYSQL_DB_USER}"
        echo "  Password: ${MYSQL_DB_PASSWORD}"
    fi
    echo ""
fi

# Next steps
log_info "Next steps:"
[ "$INSTALL_NGINX" = true ] && echo "  - Nginx is running on port 80"
[ "$INSTALL_PHP" = true ] && echo "  - Test PHP: http://your-server-ip/info.php"
[ "$INSTALL_PHP" = true ] && echo "  - Remove info.php after testing: sudo rm /var/www/html/info.php"
[ "$INSTALL_MYSQL" = true ] && echo "  - Connect to MySQL: mysql -u root -p"
[ "$INSTALL_SUPERVISOR" = true ] && echo "  - Add Supervisor configs to: /etc/supervisor/conf.d/"
[ "$INSTALL_NVM" = true ] && echo "  - Use Node.js: su - $ACTUAL_USER"
[ "$INSTALL_NVM" = true ] && echo "  - Node commands: node, npm, yarn, pm2"

echo ""
log_info "Service status:"
[ "$INSTALL_NGINX" = true ] && systemctl is-active --quiet nginx && echo "  ✓ Nginx: running" || echo "  ✗ Nginx: not running"
[ "$INSTALL_PHP" = true ] && systemctl is-active --quiet php${PHP_VERSION}-fpm && echo "  ✓ PHP-FPM: running" || echo "  ✗ PHP-FPM: not running"
[ "$INSTALL_MYSQL" = true ] && systemctl is-active --quiet mysql && echo "  ✓ MySQL: running" || echo "  ✗ MySQL: not running"
[ "$INSTALL_SUPERVISOR" = true ] && systemctl is-active --quiet supervisor && echo "  ✓ Supervisor: running" || echo "  ✗ Supervisor: not running"

echo ""
log_info "Installation log saved. Review any warnings above."
echo ""
