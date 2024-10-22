#!/bin/bash

# Colorize output
log_info() {
  echo -e "\033[32m[INFO]\033[0m $1"
}

log_warning() {
  echo -e "\033[33m[WARNING]\033[0m $1"
}

log_error() {
  echo -e "\033[31m[ERROR]\033[0m $1"
}

# Ensure ~/.ssh directory exists
ensure_ssh_dir_exists() {
  if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh" || { log_error "Failed to create ~/.ssh directory"; exit 1; }
    log_info "Created ~/.ssh directory"
  fi
}

# Ensure ~/.ssh/config file exists
ensure_config_exists() {
  if [ ! -f "$HOME/.ssh/config" ]; then
    touch "$HOME/.ssh/config" || { log_error "Failed to create ~/.ssh/config"; exit 1; }
    log_info "Created ~/.ssh/config file"
  fi
}

# Add SSH key to agent
add_key_to_ssh_agent() {
  local key_file="$1"
  ssh-add "$key_file" || { log_error "Failed to add $key_file to SSH agent"; exit 1; }
  log_info "Added $key_file to SSH agent"
}

# Remove SSH key from agent
remove_key_from_ssh_agent() {
  local key_file="$1"
  ssh-add -d "$key_file" || { log_warning "Failed to remove $key_file from SSH agent"; }
  log_info "Removed $key_file from SSH agent"
}
