#!/bin/bash

# Load utils
source "$(dirname "$0")/utils.sh"

YAML_CONFIG="$HOME/.config/gh-ssh/config.yaml"
SSH_CONFIG="$HOME/.ssh/config"

# Function to test SSH connection
test_ssh_connection() {
  local host_name=$1
  local user=$2

  log_info "Testing SSH connection for $host_name..."

  # Run the SSH command and capture both the output and the exit code
  output=$(ssh -T "$user@$host_name" 2>&1)
  exit_code=$?

  if [[ "$output" == *"You've successfully authenticated"* ]]; then
    log_info "Successfully connected to $host_name using the specified key."
  elif [[ $exit_code -eq 255 ]]; then
    log_error "Failed to connect to $host_name using the specified key. Permission denied (publickey)."
  else
    log_error "Failed to connect to $host_name using the specified key."
    echo "$output"  # Output full details for troubleshooting
  fi
}

# List all SSH hosts from the .ssh/config file
log_info "Listing all SSH hosts found in $SSH_CONFIG..."

hosts=($(grep -E '^Host ' "$SSH_CONFIG" | awk '{print $2}'))

# Exit if no hosts are found
if [ ${#hosts[@]} -eq 0 ]; then
  log_error "No SSH hosts found in $SSH_CONFIG."
  exit 1
fi

# Display the list of hosts to the user for selection
echo "Select a host to test SSH connection:"
for i in "${!hosts[@]}"; do
  echo "$(($i + 1))) ${hosts[$i]}"
done

# Prompt user for host selection
read -p "Select a host to test SSH connection: [1-${#hosts[@]}] " selected_host_index
selected_host="${hosts[$((selected_host_index - 1))]}"

# Retrieve the user for the selected host from the YAML config
host_user=$(yq e ".keys[] | select(.host == \"$selected_host\") | .user" "$YAML_CONFIG")

# If user is empty, default to "git"
if [ -z "$host_user" ]; then
  host_user="git"
fi

# Test the SSH connection for the selected host
test_ssh_connection "$selected_host" "$host_user"
