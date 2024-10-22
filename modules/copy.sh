#!/bin/bash

# Load utils
source "$(dirname "$0")/utils.sh"

SSH_CONFIG="$HOME/.ssh/config"

# Ensure the SSH directory and config exist
ensure_ssh_dir_exists
ensure_config_exists

log_info "Listing all SSH hosts found in $SSH_CONFIG..."

# Extract host list from .ssh/config
hosts=($(grep -E '^Host ' "$SSH_CONFIG" | awk '{print $2}'))

# Check if hosts were found
if [ ${#hosts[@]} -eq 0 ]; then
  log_warning "No hosts found in $SSH_CONFIG"
  exit 1
fi

# Display hosts and allow the user to select one
for i in "${!hosts[@]}"; do
  echo "$((i+1))) ${hosts[$i]}"
done

read -p "Select a host to copy the public key: [1-${#hosts[@]}] " host_idx

selected_host="${hosts[$((host_idx-1))]}"
log_info "Copying public key for $selected_host..."

# Find the identity file path for the selected host by ensuring to get the IdentityFile line directly after the Host entry
key_file=$(awk "/Host $selected_host/{flag=1;next}/Host /{flag=0}flag" "$SSH_CONFIG" | grep "IdentityFile" | awk '{print $2}')

# Expand ~ to $HOME if present in the path
key_file_expanded="${key_file/#\~/$HOME}"

# Check if the public key exists
if [ ! -f "$key_file_expanded.pub" ]; then
  log_error "Public key not found for $selected_host"
  exit 1
fi

# Copy the public key to clipboard
cat "$key_file_expanded.pub" | pbcopy
log_info "Public key copied to clipboard. Paste it into your GitHub account."
