#!/usr/bin/env bash
# Task Tracker Installation Script
# Installs task-tracker to /usr/local/bin and sets up shell completions
set -euo pipefail

TASK_TRACKER_REPO_USER="${TASK_TRACKER_REPO_USER:-jeromecoloma}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
CONFIG_DIR="${HOME}/.config/task-tracker"

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

die() { printf "${RED}❌ %s${RESET}\n" "$*" >&2; exit 1; }
info() { printf "${BLUE}ℹ️  %s${RESET}\n" "$*" >&2; }
success() { printf "${GREEN}✅ %s${RESET}\n" "$*" >&2; }
warn() { printf "${YELLOW}⚠️  %s${RESET}\n" "$*" >&2; }

# Check if running with sufficient privileges
check_privileges() {
  if [[ ! -w "$INSTALL_DIR" ]]; then
    if [[ $EUID -ne 0 ]]; then
      die "Installation requires write access to $INSTALL_DIR. Please run with sudo or as root."
    fi
  fi
}

# Check dependencies
check_dependencies() {
  local missing=()
  
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    missing+=("curl or wget")
  fi
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    die "Missing required dependencies: ${missing[*]}"
  fi
}

# Download file
download_file() {
  local url="$1"
  local output="$2"
  
  info "Downloading from $url..."
  
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$output" || die "Failed to download $url"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$output" "$url" || die "Failed to download $url"
  else
    die "Neither curl nor wget available"
  fi
}

# Install task-tracker
install_task_tracker() {
  local script_url="https://raw.githubusercontent.com/$TASK_TRACKER_REPO_USER/task-tracker/main/task-tracker"
  local target="$INSTALL_DIR/task-tracker"
  
  info "Installing task-tracker to $target..."
  
  # Create install directory if it doesn't exist
  if [[ ! -d "$INSTALL_DIR" ]]; then
    mkdir -p "$INSTALL_DIR" || die "Failed to create $INSTALL_DIR"
  fi
  
  # Download and install
  download_file "$script_url" "$target"
  chmod +x "$target" || die "Failed to make $target executable"
  
  success "task-tracker installed to $target"
}

# Install configuration directory
install_config() {
  info "Setting up configuration directory..."
  
  if [[ ! -d "$CONFIG_DIR" ]]; then
    mkdir -p "$CONFIG_DIR" || die "Failed to create config directory $CONFIG_DIR"
  fi
  
  # Download example configuration
  local example_url="https://raw.githubusercontent.com/$TASK_TRACKER_REPO_USER/task-tracker/main/.tasktrackerrc.example"
  local example_target="$CONFIG_DIR/.tasktrackerrc.example"
  
  download_file "$example_url" "$example_target" || warn "Failed to download example configuration"
  
  if [[ -f "$example_target" ]]; then
    success "Example configuration installed to $example_target"
  fi
}

# Verify dependencies are installed
verify_dependencies() {
  local missing=()
  
  info "Checking for required dependencies..."
  
  if ! command -v toggl-track >/dev/null 2>&1; then
    missing+=("toggl-track")
  fi
  
  if ! command -v zendesk-cli >/dev/null 2>&1; then
    missing+=("zendesk-cli")
  fi
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    warn "Missing dependencies detected: ${missing[*]}"
    printf "\n${YELLOW}Please install the following dependencies:${RESET}\n" >&2
    
    if [[ " ${missing[*]} " =~ " toggl-track " ]]; then
      printf "  ${GREEN}toggl-track:${RESET} curl -fsSL https://raw.githubusercontent.com/jeromecoloma/toggl-track/main/install.sh | bash\n" >&2
    fi
    
    if [[ " ${missing[*]} " =~ " zendesk-cli " ]]; then
      printf "  ${GREEN}zendesk-cli:${RESET} curl -fsSL https://raw.githubusercontent.com/jeromecoloma/zendesk-cli/main/install.sh | bash\n" >&2
    fi
    
    printf "\n${BLUE}You can install task-tracker without these dependencies, but they're required for full functionality.${RESET}\n" >&2
    printf "Continue installation? (y/N): " >&2
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      die "Installation cancelled"
    fi
  else
    success "All dependencies are installed"
  fi
}

# Test installation
test_installation() {
  info "Testing installation..."
  
  if command -v task-tracker >/dev/null 2>&1; then
    task-tracker --version >&2
    success "Installation successful!"
  else
    warn "task-tracker not found in PATH. You may need to restart your shell or add $INSTALL_DIR to your PATH."
  fi
}

# Uninstall function
uninstall_task_tracker() {
  info "Uninstalling task-tracker..."
  
  local target="$INSTALL_DIR/task-tracker"
  
  if [[ -f "$target" ]]; then
    rm "$target" || die "Failed to remove $target"
    success "Removed $target"
  else
    warn "task-tracker not found at $target"
  fi
  
  if [[ -d "$CONFIG_DIR" ]]; then
    printf "Remove configuration directory $CONFIG_DIR? (y/N): " >&2
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      rm -rf "$CONFIG_DIR" || warn "Failed to remove $CONFIG_DIR"
      success "Removed configuration directory"
    fi
  fi
  
  success "Uninstallation complete"
}

# Main installation function
main() {
  local force=false
  local uninstall=false
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)
        force=true
        shift
        ;;
      --uninstall)
        uninstall=true
        shift
        ;;
      --help|-h)
        cat <<HELP
Task Tracker Installation Script

Usage: $0 [options]

Options:
  --force        Force reinstallation even if already installed
  --uninstall    Uninstall task-tracker
  --help, -h     Show this help message

Environment Variables:
  TASK_TRACKER_REPO_USER    GitHub username (default: jeromecoloma)
  INSTALL_DIR               Installation directory (default: /usr/local/bin)

Examples:
  $0                        # Standard installation
  $0 --force               # Force reinstall
  $0 --uninstall           # Uninstall task-tracker
  sudo $0                  # Install with elevated privileges
HELP
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done
  
  printf "\n${BLUE}${BOLD}📋 Task Tracker Installation${RESET}\n\n" >&2
  
  if [[ "$uninstall" == "true" ]]; then
    check_privileges
    uninstall_task_tracker
    return 0
  fi
  
  # Check if already installed
  if command -v task-tracker >/dev/null 2>&1 && [[ "$force" != "true" ]]; then
    warn "task-tracker is already installed. Use --force to reinstall."
    task-tracker --version
    exit 0
  fi
  
  check_dependencies
  check_privileges
  verify_dependencies
  install_task_tracker
  install_config
  test_installation
  
  printf "\n${GREEN}${BOLD}🎉 Installation Complete!${RESET}\n\n" >&2
  printf "${BLUE}Next steps:${RESET}\n" >&2
  printf "1. Run: ${GREEN}task-tracker init${RESET} to set up configuration\n" >&2
  printf "2. Make sure toggl-track and zendesk-cli are configured\n" >&2
  printf "3. Start tracking: ${GREEN}task-tracker start \"Task description\" 12345${RESET}\n\n" >&2
}

main "$@"