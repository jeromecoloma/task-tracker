#!/usr/bin/env bash
# Task Tracker Local Installation Script
# Installs task-tracker to ~/bin for local development and testing
set -euo pipefail

# Configuration
INSTALL_DIR="${INSTALL_DIR:-$HOME/bin}"
COMPLETION_DIR="${COMPLETION_DIR:-$HOME/.zsh/completions}"
CONFIG_DIR="${HOME}/.config/task-tracker"
SCRIPT_NAME="task-tracker"

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

# Check if we're in the project directory
check_project_directory() {
  if [[ ! -f "./task-tracker" ]]; then
    die "Must be run from the task-tracker project directory containing the task-tracker script"
  fi
  
  if [[ ! -x "./task-tracker" ]]; then
    die "task-tracker script is not executable. Run: chmod +x task-tracker"
  fi
}

# Create necessary directories
create_directories() {
  info "Creating installation directories..."
  
  # Create ~/bin directory
  if [[ ! -d "$INSTALL_DIR" ]]; then
    mkdir -p "$INSTALL_DIR" || die "Failed to create $INSTALL_DIR"
    success "Created $INSTALL_DIR"
  else
    info "$INSTALL_DIR already exists"
  fi
  
  # Create config directory
  if [[ ! -d "$CONFIG_DIR" ]]; then
    mkdir -p "$CONFIG_DIR" || die "Failed to create $CONFIG_DIR"
    success "Created $CONFIG_DIR"
  else
    info "$CONFIG_DIR already exists"
  fi
}

# Install task-tracker script
install_task_tracker() {
  local source_script="./task-tracker"
  local target_script="$INSTALL_DIR/$SCRIPT_NAME"
  
  info "Installing task-tracker to $target_script..."
  
  # Create backup of existing installation
  if [[ -f "$target_script" ]]; then
    local backup_file="${target_script}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$target_script" "$backup_file" || warn "Failed to create backup"
    if [[ -f "$backup_file" ]]; then
      info "Created backup: $backup_file"
    fi
  fi
  
  # Copy script to target location
  cp "$source_script" "$target_script" || die "Failed to copy script to $target_script"
  chmod +x "$target_script" || die "Failed to make script executable"
  
  success "task-tracker installed to $target_script"
}

# Install configuration files
install_config() {
  info "Installing configuration files..."
  
  # Install example configuration
  if [[ -f "./.tasktrackerrc.example" ]]; then
    local example_target="$CONFIG_DIR/.tasktrackerrc.example"
    cp "./.tasktrackerrc.example" "$example_target" || warn "Failed to copy example config"
    if [[ -f "$example_target" ]]; then
      success "Example configuration installed to $example_target"
    fi
  else
    warn "No .tasktrackerrc.example found in current directory"
  fi
}

# Check if ~/bin is in PATH
check_path() {
  info "Checking PATH configuration..."
  
  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    warn "$INSTALL_DIR is not in your PATH"
    info "To fix this, add the following line to your shell config file:"
    info "  ~/.zshrc (for zsh) or ~/.bashrc (for bash):"
    echo ""
    printf "${YELLOW}export PATH=\"\$HOME/bin:\$PATH\"${RESET}\n"
    echo ""
    info "Then restart your shell or run: source ~/.zshrc"
    return 1
  else
    success "$INSTALL_DIR is already in your PATH"
    return 0
  fi
}

# Verify dependencies are available
check_dependencies() {
  local missing=()
  
  info "Checking for required dependencies..."
  
  # Check toggl-track
  if command -v toggl-track >/dev/null 2>&1; then
    local toggl_location
    toggl_location=$(command -v toggl-track)
    success "toggl-track found at: $toggl_location"
  else
    missing+=("toggl-track")
    warn "toggl-track: not installed"
  fi
  
  # Check zendesk-cli
  if command -v zendesk-cli >/dev/null 2>&1; then
    local zendesk_location
    zendesk_location=$(command -v zendesk-cli)
    success "zendesk-cli found at: $zendesk_location"
  else
    missing+=("zendesk-cli")
    warn "zendesk-cli: not installed"
  fi
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    printf "\n${YELLOW}Please install the following dependencies:${RESET}\n" >&2
    
    if [[ " ${missing[*]} " =~ " toggl-track " ]]; then
      printf "  ${GREEN}toggl-track:${RESET} curl -fsSL https://raw.githubusercontent.com/jeromecoloma/toggl-track/main/install.sh | bash\n" >&2
    fi
    
    if [[ " ${missing[*]} " =~ " zendesk-cli " ]]; then
      printf "  ${GREEN}zendesk-cli:${RESET} curl -fsSL https://raw.githubusercontent.com/jeromecoloma/zendesk-cli/main/install.sh | bash\n" >&2
    fi
    
    printf "\n${BLUE}task-tracker will be installed but may not work until dependencies are available.${RESET}\n" >&2
    return 1
  else
    success "All dependencies are available"
    return 0
  fi
}

# Test installation
test_installation() {
  info "Testing installation..."
  
  if [[ -x "$INSTALL_DIR/$SCRIPT_NAME" ]]; then
    if command -v "$SCRIPT_NAME" >/dev/null 2>&1; then
      "$SCRIPT_NAME" --version >&2
      success "Installation successful!"
    else
      warn "task-tracker installed but not in PATH. You may need to restart your shell."
    fi
  else
    die "Installation verification failed"
  fi
}

# Run tests if available
run_tests() {
  if [[ -x "./test-task-tracker.sh" ]]; then
    info "Running test suite..."
    if ./test-task-tracker.sh >&2; then
      success "All tests passed!"
    else
      warn "Some tests failed. Installation may have issues."
      return 1
    fi
  else
    warn "No test suite found (./test-task-tracker.sh)"
  fi
}

# Uninstall function
uninstall_task_tracker() {
  local target_script="$INSTALL_DIR/$SCRIPT_NAME"
  local has_backups=false
  local has_config=false
  
  # Check if anything is actually installed
  if [[ ! -f "$target_script" ]]; then
    # Check for backup files
    if ls "${target_script}.backup."* >/dev/null 2>&1; then
      has_backups=true
    fi
    # Check for config directory
    if [[ -d "$CONFIG_DIR" ]]; then
      has_config=true
    fi
    
    # If nothing is installed, just say so and exit
    if [[ "$has_backups" == "false" && "$has_config" == "false" ]]; then
      printf "\n${YELLOW}⚠️  Task Tracker is not installed${RESET}\n" >&2
      printf "${BLUE}💡 Nothing to uninstall${RESET}\n\n" >&2
      return 0
    fi
  fi
  
  info "Uninstalling task-tracker..."
  
  if [[ -f "$target_script" ]]; then
    rm "$target_script" || die "Failed to remove $target_script"
    success "Removed $target_script"
  else
    warn "task-tracker not found at $target_script"
  fi
  
  # Remove backups (optional)
  if ls "${target_script}.backup."* >/dev/null 2>&1; then
    printf "Remove backup files too? (y/N): " >&2
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      rm "${target_script}.backup."* || warn "Failed to remove some backups"
      success "Removed backup files"
    fi
  fi
  
  # Remove config directory (optional)
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

# Show project information
show_project_info() {
  local operation="${1:-install}"
  
  if [[ "$operation" == "uninstall" ]]; then
    printf "\n${BLUE}${BOLD}📋 Task Tracker Local Uninstallation${RESET}\n\n" >&2
    info "Uninstalling: Task Tracker"
  else
    printf "\n${BLUE}${BOLD}📋 Task Tracker Local Installation${RESET}\n\n" >&2
    
    if [[ -f "./task-tracker" ]]; then
      local version
      version=$(./task-tracker --version 2>/dev/null | grep -i "version:" | head -1 | sed 's/.*Version:[[:space:]]*//' || echo "Unknown version")
      if [[ -n "$version" && "$version" != "Unknown version" ]]; then
        info "Installing: Task Tracker v$version"
      else
        info "Installing: Task Tracker (version detection failed)"
      fi
    fi
  fi
  
  info "Project directory: $(pwd)"
  info "Install directory: $INSTALL_DIR"
  info "Config directory: $CONFIG_DIR"
  echo ""
}

# Main installation function
main() {
  local force=false
  local run_tests_flag=true
  local uninstall=false
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)
        force=true
        shift
        ;;
      --no-test)
        run_tests_flag=false
        shift
        ;;
      --uninstall)
        uninstall=true
        shift
        ;;
      --help|-h)
        cat <<HELP
Task Tracker Local Installation Script

Usage: $0 [options]

Options:
  --force        Force reinstallation even if already installed
  --no-test      Skip running test suite after installation
  --uninstall    Uninstall task-tracker
  --help, -h     Show this help message

Environment Variables:
  INSTALL_DIR    Installation directory (default: ~/bin)
  CONFIG_DIR     Config directory (default: ~/.config/task-tracker)

Examples:
  $0                    # Standard local installation
  $0 --force           # Force reinstall
  $0 --no-test         # Install without running tests
  $0 --uninstall       # Remove installation

Note: Must be run from the task-tracker project directory
HELP
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done
  
  if [[ "$uninstall" == "true" ]]; then
    # Check if anything is installed first
    local target_script="$INSTALL_DIR/$SCRIPT_NAME"
    local has_backups=false
    local has_config=false
    
    if ls "${target_script}.backup."* >/dev/null 2>&1; then
      has_backups=true
    fi
    if [[ -d "$CONFIG_DIR" ]]; then
      has_config=true
    fi
    
    # Only show project info if something is actually installed
    if [[ -f "$target_script" || "$has_backups" == "true" || "$has_config" == "true" ]]; then
      show_project_info "uninstall"
    fi
    
    uninstall_task_tracker
    return 0
  fi
  
  show_project_info
  
  check_project_directory
  
  # Check if already installed locally (in our target directory)
  local target_script="$INSTALL_DIR/$SCRIPT_NAME"
  if [[ -f "$target_script" ]] && [[ "$force" != "true" ]]; then
    warn "task-tracker is already installed locally at $target_script"
    info "Use --force to reinstall, or check version:"
    if [[ -x "$target_script" ]]; then
      "$target_script" --version || info "Existing installation may be broken"
    fi
    exit 0
  elif command -v task-tracker >/dev/null 2>&1 && [[ "$force" != "true" ]]; then
    # Found task-tracker elsewhere in PATH but not locally
    local existing_location
    existing_location=$(command -v task-tracker)
    info "Found existing task-tracker installation at: $existing_location"
    info "This will install a local development copy to: $target_script"
    info "The local version will take precedence if ~/bin is first in PATH"
    printf "Continue with local installation? (y/N): " >&2
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
      info "Installation cancelled"
      exit 0
    fi
  fi
  
  create_directories
  check_dependencies
  install_task_tracker
  install_config
  
  local path_ok=0
  check_path || path_ok=1
  
  test_installation
  
  if [[ "$run_tests_flag" == "true" ]]; then
    echo ""
    run_tests
  fi
  
  printf "\n${GREEN}${BOLD}🎉 Local Installation Complete!${RESET}\n\n" >&2
  
  # Show which version will be used
  if command -v task-tracker >/dev/null 2>&1; then
    local active_location
    active_location=$(command -v task-tracker)
    if [[ "$active_location" == "$INSTALL_DIR/$SCRIPT_NAME" ]]; then
      success "Local development version is active: $active_location"
    else
      warn "System version is still active: $active_location"
      info "Local version installed at: $INSTALL_DIR/$SCRIPT_NAME"
      if [[ $path_ok -ne 0 ]]; then
        info "Add ~/bin to PATH to use the local development version"
      fi
    fi
  fi
  
  if [[ $path_ok -eq 0 ]]; then
    printf "\n${BLUE}You can now run:${RESET}\n" >&2
    printf "  task-tracker init\n" >&2
    printf "  task-tracker start 12345\n" >&2
  else
    printf "\n${YELLOW}Please add ~/bin to your PATH and restart your shell${RESET}\n" >&2
    printf "Then run: task-tracker init\n" >&2
  fi
  
  printf "\n${BLUE}Development tips:${RESET}\n" >&2
  printf "  - Edit ./task-tracker and re-run this script to update\n" >&2
  printf "  - Run ./test-task-tracker.sh to test changes\n" >&2
  printf "  - Use --uninstall to remove local installation\n" >&2
}

main "$@"