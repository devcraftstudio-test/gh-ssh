#!/bin/bash

# Set utility directory (the script can be run from anywhere)
UTIL_DIR="$(dirname "$0")/modules"

# Display options to the user
echo "Welcome to the SSH Key Manager"
echo "1) Sync SSH keys"
echo "2) Copy public key to GitHub"
echo "3) Test SSH connection"
echo "4) Exit"

# Read user selection
read -p "Select an option: [1-4] " option

# Call the corresponding module
case $option in
  1)
    "$UTIL_DIR/sync.sh"
    ;;
  2)
    "$UTIL_DIR/copy.sh"
    ;;
  3)
    "$UTIL_DIR/test.sh"
    ;;
  4)
    echo "Goodbye!"
    exit 0
    ;;
  *)
    echo "Invalid option. Please select a valid option."
    ;;
esac
