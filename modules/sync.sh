#!/bin/bash

# Load utils
source "$(dirname "$0")/utils.sh"

YAML_CONFIG="$HOME/.config/gh-ssh/config.yaml"
SSH_CONFIG="$HOME/.ssh/config"

ensure_ssh_dir_exists

# Clear the SSH agent
log_info "Clearing all keys from the SSH agent..."
ssh-add -D || { log_error "Failed to clear SSH agent"; exit 1; }
log_info "All identities removed."

# Recreate .ssh/config
log_info "Recreating $SSH_CONFIG..."

# Create a backup of the old .ssh/config if it exists
if [ -f "$SSH_CONFIG" ]; then
  cp "$SSH_CONFIG" "$SSH_CONFIG.bak"
fi

# Initialize the new .ssh/config file
> "$SSH_CONFIG"  # Empty the config file to recreate it

# Get the list of hosts from the YAML file
yaml_hosts=()
for index in $(yq e '.keys | keys | .[]' "$YAML_CONFIG"); do
  host=$(yq e ".keys[$index].host" "$YAML_CONFIG")
  host_name=$(yq e ".keys[$index].host_name" "$YAML_CONFIG")
  user=$(yq e ".keys[$index].user" "$YAML_CONFIG")
  identity_file=$(yq e ".keys[$index].identity_file" "$YAML_CONFIG")
  auto_add=$(yq e ".keys[$index].auto_add" "$YAML_CONFIG")
  identities_only=$(yq e ".keys[$index].identities_only" "$YAML_CONFIG")

  # Expand ~ to $HOME for internal use
  identity_file_expanded="${identity_file/#\~/$HOME}"

  yaml_hosts+=("$host")

  # Append the host configuration to the .ssh/config file
  {
    echo "Host $host"
    echo "  HostName $host_name"
    echo "  User $user"
    echo "  IdentityFile $identity_file"
    echo "  IdentitiesOnly $identities_only"
  } >> "$SSH_CONFIG"
  
  # Check if the key file exists, and prompt the user to create it if it doesn't
  if [ ! -f "$identity_file_expanded" ]; then
    read -p "Do you want to create a new SSH key for $host (this will add the key to the config and agent)? (y/n) " create_key
    if [ "$create_key" = "y" ]; then
      log_info "Generating SSH key for $host..."
      ssh-keygen -t ed25519 -C "$email" -f "$identity_file_expanded" -N ""
      
      if [ "$auto_add" = "true" ]; then
        log_info "Adding $identity_file_expanded to the SSH agent..."
        add_key_to_ssh_agent "$identity_file_expanded"
      fi
    fi
  else
    if [ "$auto_add" = "true" ]; then
      log_info "Adding $identity_file_expanded to the SSH agent..."
      add_key_to_ssh_agent "$identity_file_expanded"
    fi
  fi
done

# Get the list of hosts in the current .ssh/config (before syncing)
ssh_hosts=($(grep -E '^Host ' "$SSH_CONFIG.bak" | awk '{print $2}'))

# Loop through the hosts that were in the old SSH config but are no longer in YAML
for ssh_host in "${ssh_hosts[@]}"; do
  if [[ ! " ${yaml_hosts[@]} " =~ " ${ssh_host} " ]]; then
    read -p "Do you want to remove $ssh_host and its key files (this will remove the entry from config and delete the key)? (y/n) " remove_key
    if [ "$remove_key" = "y" ]; then
      log_info "Removing host $ssh_host from $SSH_CONFIG and deleting associated key files..."

      # Find the IdentityFile line for the host in .ssh/config
      identity_file=$(awk "/Host $ssh_host/{flag=1;next}/Host /{flag=0}flag" "$SSH_CONFIG.bak" | grep "IdentityFile" | awk '{print $2}')
      identity_file_expanded="${identity_file/#\~/$HOME}"

      # Check if the key file exists and remove it
      if [ -f "$identity_file_expanded" ]; then
        rm -f "$identity_file_expanded" "$identity_file_expanded.pub"
        log_info "Removed SSH key files for $ssh_host"
      else
        log_warning "No key files found for $ssh_host, or they were already removed."
      fi
    fi
  fi
done

# Remove the backup after syncing
rm -f "$SSH_CONFIG.bak"

log_info "Sync completed."
