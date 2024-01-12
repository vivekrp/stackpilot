#!/bin/bash

# Call the function to source profile files
source_profiles

# Initialize variables with default values
BUN_VERSION="${BUN_VERSION:-latest}" # Use environment variable or default to the latest version

# Function to get the installed version of Bun
get_installed_bun_version() {
    if command -v bun &>/dev/null; then
        local version
        version=$(bun --version | grep -oE '^[0-9]+\.[0-9]+\.[0-9]+')
        echo "Installed Bun version: $version" >&2
        echo "$version"
    else
        echo "Bun is not installed." >&2
        echo ""
    fi
}

# Function to compare versions
is_version_equal() {
    [[ "$1" == "$2" ]]
}

# Function to check if the latest version is installed
is_latest_version_installed() {
    local latest_version
    latest_version=$(curl -s https://api.github.com/repos/oven-sh/bun/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    latest_version=${latest_version#bun-v} # Strip the 'bun-v' prefix
    echo "Latest Bun version: $latest_version" >&2
    is_version_equal "$(get_installed_bun_version)" "$latest_version"
}

check_version_exists() {
    local version=$1
    local status_code
    status_code=$(curl -o /dev/null -s -w "%{http_code}\n" "https://github.com/oven-sh/bun/releases/tag/bun-v$version")

    if [ "$status_code" -ne 200 ]; then
        echo "This Bun version $version does not exist."
        return 1
    fi
    return 0
}

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
    local installed_version
    local bun_path="$HOME/.bun/bin"

    installed_version=$(get_installed_bun_version)

    echo "Requested Bun version: $BUN_VERSION" >&2
    echo "Installed Bun version: $installed_version" >&2

    # Check if a specific version is requested and it exists
    if [[ "$BUN_VERSION" != "latest" ]]; then
        if ! check_version_exists "$BUN_VERSION"; then
            exit 1
        fi
    fi

    if [[ -n "$installed_version" ]]; then
        if [[ "$BUN_VERSION" == "latest" ]]; then
            if is_latest_version_installed; then
                echo "The latest version of Bun is already installed."
                return 0
            else
                echo "Upgrading Bun to the latest version..."
                if ! bun upgrade; then
                    echo "Failed to upgrade Bun."
                    exit 1
                fi
                return $?
            fi
        elif is_version_equal "$installed_version" "$BUN_VERSION"; then
            echo "Bun version $BUN_VERSION is already installed."
            return 0
        fi
    fi

    echo "Installing Bun..."
    if [[ "$BUN_VERSION" == "latest" ]]; then
        # Install the latest version of Bun
        curl -fsSL https://bun.sh/install | bash
    else
        # Install the specified version of Bun, ensuring it has the 'bun-v' prefix
        local version_to_install="bun-v$BUN_VERSION"
        curl -fsSL https://bun.sh/install | bash -s -- "$version_to_install"
    fi

    # Add Bun to the PATH for the current session
    export PATH="$bun_path:$PATH"

    # Check if installation was successful
    if ! command -v bun &>/dev/null; then
        echo "Bun installation failed."
        exit 1
    fi

    echo "Bun installed successfully."
}

is_cowsay_installed() {
    if command -v cowsay &>/dev/null; then
        echo "cowsay is already installed." >&2
        return 0
    else
        echo "cowsay is not installed." >&2
        return 1
    fi
}

install_cowsay() {
    if ! is_cowsay_installed; then
        echo "Installing cowsay..."
        bun install --global cowsay
        echo "cowsay installed successfully."
    else
        echo "Skipping installation of cowsay, it is already installed."
    fi
}

# Function to check if @antfu/ni is installed
is_ni_installed() {
    if command -v ni &>/dev/null; then
        echo "ni is already installed." >&2
        return 0
    else
        echo "ni is not installed." >&2
        return 1
    fi
}

# Install @antfu/ni if it's not already installed
install_ni() {
    if ! is_ni_installed; then
        echo "Installing @antfu/ni..."
        bun i -g @antfu/ni
        echo "@antfu/ni installed successfully."
    else
        echo "Skipping installation of @antfu/ni, it is already installed."
    fi
}

install_bun "$BUN_VERSION" # Call the function to install Bun with the optional version

bun update -g

ln ~/.bun/bin/bun ~/.bun/bin/node

install_cowsay # Call the function to install cowsay if it's not already installed

cowsay "Bun!"

install_ni
