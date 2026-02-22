#!/bin/bash

# Development Environment Setup Script
# Installs: VSCode, Node.js, PM2, Neovim 0.11.4, dependencies(ripgrep, fd-find, fzf, lazygit),
# GitHub CLI, MEGAsync, Java JRE, MariaDB, PostgreSQL 17, Docker, PHP, oh-my-zsh, python venv

set -e # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
  log_error "This script should not be run as root. Run as normal user with sudo privileges."
  exit 1
fi

# Update system
log_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install common dependencies
log_info "Installing common dependencies..."
sudo apt install -y curl wget git apt-transport-https software-properties-common ca-certificates gnupg lsb-release build-essential

# Install VSCode
log_info "Installing Visual Studio Code..."
if ! command -v code &>/dev/null; then
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
  rm -f packages.microsoft.gpg
  sudo apt update
  sudo apt install -y code
  log_info "VSCode installed successfully"
else
  log_warn "VSCode already installed"
fi

# Install NVM (Node Version Manager)
log_info "Installing NVM..."
if [[ ! -d "$HOME/.nvm" ]]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

  # Load NVM into current shell
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  log_info "NVM installed successfully"
else
  log_warn "NVM already installed"
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Install Node.js via NVM
log_info "Installing Node.js LTS via NVM..."
if command -v nvm &>/dev/null; then
  nvm install --lts
  nvm use --lts
  nvm alias default 'lts/*'
  log_info "Node.js $(node --version) and npm $(npm --version) installed successfully"
else
  log_error "NVM installation failed, falling back to NodeSource"
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
  log_info "Node.js $(node --version) and npm $(npm --version) installed successfully"
fi

# Install Neovim (latest stable)
log_info "Installing Neovim (latest stable)..."
if ! command -v nvim &>/dev/null; then
  cd /tmp
  # Download latest stable release
  wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
  tar xzf nvim-linux-x86_64.tar.gz
  sudo rm -rf /usr/local/nvim
  sudo mv nvim-linux-x86_64 /usr/local/nvim
  sudo ln -sf /usr/local/nvim/bin/nvim /usr/local/bin/nvim
  rm nvim-linux-x86_64.tar.gz
  log_info "Neovim installed successfully: $(nvim --version | head -n1)"
else
  log_warn "Neovim already installed: $(nvim --version | head -n1)"
fi

# Install LazyVim
log_info "Installing LazyVim..."
if [[ ! -d ~/.config/nvim ]]; then
  # Backup existing config if it exists
  if [[ -d ~/.config/nvim ]]; then
    log_warn "Backing up existing Neovim config to ~/.config/nvim.backup"
    mv ~/.config/nvim ~/.config/nvim.backup
  fi
  if [[ -d ~/.local/share/nvim ]]; then
    mv ~/.local/share/nvim ~/.local/share/nvim.backup
  fi
  if [[ -d ~/.local/state/nvim ]]; then
    mv ~/.local/state/nvim ~/.local/state/nvim.backup
  fi
  if [[ -d ~/.cache/nvim ]]; then
    mv ~/.cache/nvim ~/.cache/nvim.backup
  fi

  # Clone LazyVim starter
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git
  log_info "LazyVim installed successfully"
  log_warn "Run 'nvim' to complete LazyVim installation (plugins will auto-install)"
else
  log_warn "Neovim config already exists at ~/.config/nvim"
fi

# Install GitHub CLI
log_info "Installing GitHub CLI..."
if ! command -v gh &>/dev/null; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt update
  sudo apt install -y gh
  log_info "GitHub CLI installed successfully"
else
  log_warn "GitHub CLI already installed"
fi

# Install MEGAsync
log_info "Installing MEGAsync..."
if ! command -v megasync &>/dev/null; then
  cd /tmp
  # Use Debian 12 repository
  wget https://mega.nz/linux/repo/Debian_12/amd64/megasync-Debian_12_amd64.deb
  sudo apt install -y ./megasync-Debian_12_amd64.deb || log_warn "MEGAsync installation had issues, continuing..."
  rm -f megasync-Debian_12_amd64.deb
  log_info "MEGAsync installation attempted"

else
  log_warn "MEGAsync already installed"
fi

# Install Java Runtime Environment
log_info "Installing Java JRE..."
if ! command -v java &>/dev/null; then
  sudo apt install -y default-jre
  log_info "Java JRE installed: $(java -version 2>&1 | head -n1)"
else
  log_warn "Java already installed: $(java -version 2>&1 | head -n1)"
fi

# Install Python and python3-venv
log_info "Installing Python and python3-venv..."
if ! command -v python3 &>/dev/null; then
  sudo apt install -y python3 python3-pip python3-venv python3.11-venv
  log_info "Python installed: $(python3 --version)"
else
  log_warn "Python already installed: $(python3 --version)"
  # Ensure venv packages are installed even if Python exists
  if ! dpkg -l | grep -q python3-venv; then
    sudo apt install -y python3-venv python3.11-venv
    log_info "python3-venv and python3.11-venv installed successfully"
  else
    log_warn "python3-venv already installed"
    # Still try to install python3.11-venv specifically
    sudo apt install -y python3.11-venv 2>/dev/null || log_warn "python3.11-venv may already be installed"
  fi
fi

# Verify pip3 is available
if ! command -v pip3 &>/dev/null; then
  log_error "pip3 not found after installation. Trying to install python3-pip again..."
  sudo apt install -y python3-pip
fi

# Install pynvim globally
log_info "Installing pynvim (Python provider for Neovim)..."
if ! python3 -c "import pynvim" &>/dev/null; then
  pip3 install --user pynvim --break-system-packages
  log_info "pynvim installed successfully"
else
  log_warn "pynvim already installed"
fi
log_info "Installing pynvim (Python provider for Neovim)..."
if ! python3 -c "import pynvim" &>/dev/null; then
  pip3 install --user pynvim --break-system-packages
  log_info "pynvim installed successfully"
else
  log_warn "pynvim already installed"
fi

# Install mysql-connector-python
log_info "Installing mysql-connector-python..."
if ! python3 -c "import mysql.connector" &>/dev/null; then
  pip3 install --user mysql-connector-python --break-system-packages
  log_info "mysql-connector-python installed successfully"
else
  log_warn "mysql-connector-python already installed"
fi

# Install MariaDB
log_info "Installing MariaDB Server..."
if ! command -v mysql &>/dev/null && ! command -v mariadb &>/dev/null; then
  sudo apt install -y mariadb-server mariadb-client
  sudo systemctl start mariadb
  sudo systemctl enable mariadb
  log_info "MariaDB installed successfully"
  log_warn "Run 'sudo mysql_secure_installation' to secure your MariaDB installation"
else
  log_warn "MySQL/MariaDB already installed"
fi

# Install PostgreSQL 17
log_info "Installing PostgreSQL 17..."
if ! command -v psql &>/dev/null || [[ $(psql --version | grep -o "17") != "17" ]]; then
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt update
  sudo apt install -y postgresql-17
  sudo systemctl start postgresql
  sudo systemctl enable postgresql
  log_info "PostgreSQL 17 installed successfully"
else
  log_warn "PostgreSQL already installed"
fi

# Install Docker
log_info "Installing Docker..."
if ! command -v docker &>/dev/null; then
  sudo apt install -y ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker $USER
  log_info "Docker installed successfully"
  log_warn "Log out and back in for Docker group membership to take effect"
else
  log_warn "Docker already installed"
fi

# Install PHP
log_info "Installing PHP..."
if ! command -v php &>/dev/null; then
  sudo apt install -y php php-cli php-fpm php-mysql php-pgsql php-curl php-gd php-mbstring php-xml php-zip
  log_info "PHP installed: $(php -v | head -n1)"
else
  log_warn "PHP already installed: $(php -v | head -n1)"
fi

# Install PM2 globally
log_info "Installing PM2 globally..."
if ! command -v pm2 &>/dev/null; then
  npm install -g pm2
  log_info "PM2 installed successfully: $(pm2 --version)"
else
  log_warn "PM2 already installed: $(pm2 --version)"
fi

# Install Nginx
log_info "Installing Nginx..."
if ! command -v nginx &>/dev/null; then
  sudo apt install -y nginx
  # Try to start with systemd if available, otherwise skip
  if command -v systemctl &>/dev/null && systemctl is-system-running &>/dev/null; then
    sudo systemctl start nginx
    sudo systemctl enable nginx
  else
    log_warn "systemd not available, skipping nginx service start"
  fi
  log_info "Nginx installed successfully"
else
  log_warn "Nginx already installed"
  # Check if nginx is running
  if pgrep nginx >/dev/null; then
    log_info "Nginx is already running"
  elif command -v systemctl &>/dev/null && systemctl is-system-running &>/dev/null; then
    sudo systemctl start nginx 2>/dev/null || log_warn "Could not start nginx service"
  fi
fi

# Clean up
log_info "Cleaning up..."
sudo apt autoremove -y
sudo apt clean

# Summary
echo ""
log_info "=========================================="
log_info "Installation Complete!"
log_info "=========================================="
echo ""
log_info "Installed versions:"
command -v code &>/dev/null && echo "  - VSCode: $(code --version | head -n1)"
command -v nvm &>/dev/null && echo "  - NVM: $(nvm --version)"
command -v node &>/dev/null && echo "  - Node.js: $(node --version)"
command -v npm &>/dev/null && echo "  - npm: $(npm --version)"
command -v nvim &>/dev/null && echo "  - Neovim: $(nvim --version | head -n1)"
command -v gh &>/dev/null && echo "  - GitHub CLI: $(gh --version | head -n1)"
command -v java &>/dev/null && echo "  - Java: $(java -version 2>&1 | head -n1)"
command -v mysql &>/dev/null && echo "  - MariaDB: $(mysql --version)"
command -v psql &>/dev/null && echo "  - PostgreSQL: $(psql --version)"
command -v docker &>/dev/null && echo "  - Docker: $(docker --version)"
command -v php &>/dev/null && echo "  - PHP: $(php -v | head -n1)"
command -v python3 &>/dev/null && echo "  - Python: $(python3 --version)"
echo ""
log_warn "Post-installation steps:"
echo "  1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
echo "  2. To set Zsh as default shell: chsh -s \$(which zsh)"
echo "  3. Log out and back in for Docker group to take effect"
echo "  4. Run 'sudo mysql_secure_installation' to secure MariaDB"
echo "  5. Configure PostgreSQL: 'sudo -u postgres psql'"
echo "  6. Authenticate GitHub CLI: 'gh auth login'"
echo "  7. Run 'nvim' to complete LazyVim plugin installation"
echo "  8. Verify NVM: 'nvm --version' and 'node --version'"
echo "  9. Test Python venv: 'python3 -m venv test_env && source test_env/bin/activate'"
echo ""
# install oh-my-zsh
# install python-venv
