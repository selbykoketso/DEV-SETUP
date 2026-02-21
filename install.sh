#!/bin/bash

# Development Environment Setup Script
# Installs: VSCode, Node.js, Neovim 0.11.4, GitHub CLI, MEGAsync, Java JRE, MySQL, PostgreSQL 17, Docker, PHP

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
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
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
command -v mysql &>/dev/null && echo "  - MySQL: $(mysql --version)"
command -v psql &>/dev/null && echo "  - PostgreSQL: $(psql --version)"
command -v docker &>/dev/null && echo "  - Docker: $(docker --version)"
command -v php &>/dev/null && echo "  - PHP: $(php -v | head -n1)"
echo ""
log_warn "Post-installation steps:"
echo "  1. Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
echo "  2. Log out and back in for Docker group to take effect"
echo "  3. Run 'sudo mysql_secure_installation' to secure MySQL"
echo "  4. Configure PostgreSQL: 'sudo -u postgres psql'"
echo "  5. Authenticate GitHub CLI: 'gh auth login'"
echo "  6. Run 'nvim' to complete LazyVim plugin installation"
echo "  7. Verify NVM: 'nvm --version' and 'node --version'"
echo ""
# install oh-my-zsh
# install python-venv
