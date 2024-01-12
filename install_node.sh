#!/bin/bash

# Call the function to source profile files
source_profiles

# Initialize variables with default values
NODE_VERSION="${NODE_VERSION:-latest}" # Use environment variable or default to the latest version

# Process arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --node-version)
        NODE_VERSION="$2"
        shift
        ;;
    *)
        echo "Unknown parameter passed: $1"
        exit 1
        ;;
    esac
    shift
done

# Install Bun
install_node() {
    echo "Installing Node..."
    local node_path="$HOME/.nvm/node"
    if [[ -z "$NODE_VERSION" || "$NODE_VERSION" == "latest" ]]; then
        # Install the latest version of Node
        echo "Installing the latest version of Node..."
    else
        # Install the specified version of Node
        echo "Installing Node $NODE_VERSION..."
    fi

    # Add Bun to the PATH for the current session
    export PATH="$node_path:$PATH"

    # Check if installation was successful
    if ! command -v node &>/dev/null; then
        echo "Bun installation failed."
        exit 1
    fi

    echo "Bun installed successfully."
}
install_node "$NODE_VERSION" # Call the function to install Bun with the optional version

# Install Antfu/ni a unified package runner for npm/yarn/pnpm/bun
npm i -g @antfu/ni
