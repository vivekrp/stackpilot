#!/bin/bash

# Initialize variables with default values
BUN_VERSION="${BUN_VERSION:-latest}" # Use environment variable or default to the latest version

# Process arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --bun-version)
        BUN_VERSION="$2"
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
install_bun() {
    echo "Installing Bun..."
    local bun_path="$HOME/.bun/bin"
    if [[ -z "$BUN_VERSION" || "$BUN_VERSION" == "latest" ]]; then
        # Install the latest version of Bun
        curl -fsSL https://bun.sh/install | bash
    else
        # Install the specified version of Bun
        curl -fsSL https://bun.sh/install | bash -s -- "$BUN_VERSION"
    fi

    # Add Bun to the PATH for future sessions
    add_to_path "$bun_path"

    # Add Bun to the PATH for the current session
    export PATH="$bun_path:$PATH"

    # Check if installation was successful
    if ! command -v bun &>/dev/null; then
        echo "Bun installation failed."
        exit 1
    fi

    echo "Bun installed successfully."
}
install_bun "$BUN_VERSION" # Call the function to install Bun with the optional version

# Install Antfu/ni a unified package runner for npm/yarn/pnpm/bun
bun i -g @antfu/ni
