#!/bin/bash

# Call the function to source profile files
source_profiles

# Declare global variables
OS=""
SYSTEM_PACKAGE_MANAGER=""

# Common packages to install
# shellcheck disable=SC2034
COMMON_PACKAGES=(gnupg curl git unzip wget)

# Function to detect and export the OS and the system package manager based on the OS.
detect_and_export_environment() {
    # Detect the operating system
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
    elif [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        OS=$ID
    fi

    # Determine the system package manager based on the OS
    case $OS in
    "ubuntu" | "debian")
        SYSTEM_PACKAGE_MANAGER="apt-get"
        ;;
    "centos" | "fedora" | "rhel")
        SYSTEM_PACKAGE_MANAGER="yum"
        if command -v dnf >/dev/null; then
            SYSTEM_PACKAGE_MANAGER="dnf"
        fi
        ;;
    "arch")
        SYSTEM_PACKAGE_MANAGER="pacman"
        ;;
    "macOS")
        SYSTEM_PACKAGE_MANAGER="brew"
        ;;
    *)
        echo "Unsupported operating system."
        exit 1
        ;;
    esac

    # Export the variables for global use
    export OS
    export SYSTEM_PACKAGE_MANAGER

    # Echo the detected values
    echo "Detected Operating System: $OS"
    echo "Using Package Manager: $SYSTEM_PACKAGE_MANAGER"
}

check_sudo_requirement() {
    # Check if sudo is available and required (i.e., not running as root)
    if command -v sudo &>/dev/null && [ "$(id -u)" -ne 0 ]; then
        SUDO="sudo"
    else
        SUDO=""
    fi
}

# Function to update, upgrade system packages and then install common packages
install_update_system_common_packages() {
    local system_package_manager=$1
    local -a packages=("${!2}") # Use an array to store packages

    echo "Updating and upgrading system packages..."
    case "$system_package_manager" in
    apt-get)
        if $SUDO "$system_package_manager" update -y && $SUDO "$system_package_manager" upgrade -y; then
            echo "Updated & upgraded system packages using $system_package_manager on $OS."
        else
            echo "Failed to update & upgrade system packages using $system_package_manager on $OS."
            exit 1
        fi
        ;;
    yum | dnf)
        if $SUDO "$system_package_manager" update -y && $SUDO "$system_package_manager" upgrade -y; then
            echo "Updated & upgraded system packages using $system_package_manager on $OS."
        else
            echo "Failed to update & upgrade system packages using $system_package_manager on $OS."
            exit 1
        fi
        ;;
    pacman)
        if $SUDO "$system_package_manager" -Syu --noconfirm; then
            echo "Updated & upgraded system packages using $system_package_manager on $OS."
        else
            echo "Failed to update & upgrade system packages using $system_package_manager on $OS."
            exit 1
        fi
        ;;
    brew)
        if "$system_package_manager" update && "$system_package_manager" upgrade; then
            echo "Updated & upgraded system packages using $system_package_manager on $OS."
        else
            echo "Failed to update & upgrade system packages using $system_package_manager on $OS."
            exit 1
        fi
        ;;
    *)
        echo "Unsupported package manager: $system_package_manager"
        exit 1
        ;;
    esac

    echo "Installing common packages: ${packages[*]}"
    case "$system_package_manager" in
    brew)
        if "$system_package_manager" install "${packages[@]}"; then
            echo "Successfully installed common packages using $system_package_manager on $OS."
        else
            echo "Failed to install common packages using $system_package_manager on $OS."
            exit 1
        fi
        ;;
    pacman)
        if $SUDO "$system_package_manager" -S --noconfirm "${packages[@]}"; then
            echo "Successfully installed common packages using $system_package_manager on $OS."
        else
            echo "Failed to install common packages using $system_package_manager on $OS."
            exit 1
        fi
        ;;
    *)
        if $SUDO "$system_package_manager" install -y "${packages[@]}"; then
            echo "Successfully installed common packages using $system_package_manager on $OS."
        else
            echo "Failed to install common packages using $system_package_manager on $OS."
            exit 1
        fi
        ;;
    esac
}

# Function to install and update Homebrew
install_and_update_homebrew() {
    local brew_path=""

    # Define the expected Homebrew installation paths for macOS and Linux
    local new_macos_brew_path="/opt/homebrew/bin" # Newer macOS installations
    local old_macos_brew_path="/usr/local/bin"    # Older macOS installations
    local linux_brew_path="/home/linuxbrew/.linuxbrew/bin"

    # Check if we are running on macOS or a supported Linux distribution with glibc
    if [[ "$OS" == "macOS" ]]; then
        if [[ -d "/opt/homebrew" ]]; then
            brew_path=$new_macos_brew_path
        elif [[ -d "/usr/local/Homebrew" ]]; then
            brew_path=$old_macos_brew_path
        fi
    elif [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS" == "centos" || "$OS" == "fedora" || "$OS" == "rhel" || "$OS" == "arch" ]]; then
        if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
            brew_path=$linux_brew_path
        fi
    fi

    # If brew_path is set, Homebrew is likely installed
    if [[ -n "$brew_path" ]]; then
        echo "Homebrew is already installed at $brew_path."
    else
        # Install Homebrew/Linuxbrew
        echo "Installing Homebrew/Linuxbrew..."
        yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # After installation, set the brew_path according to the OS
        if [[ "$OS" == "macOS" ]]; then
            brew_path=$new_macos_brew_path
        else
            brew_path=$linux_brew_path
        fi
        echo "Homebrew/Linuxbrew installation complete."
    fi

    eval "$($brew_path/brew shellenv)"
    # Add Homebrew to the PATH for the current session
    export PATH="$brew_path:$PATH"

    # Add Homebrew to the PATH for future sessions
    add_to_path "$brew_path"

    # Check if Homebrew commands are available after updating the PATH
    if command -v brew >/dev/null 2>&1; then
        # Update and upgrade Homebrew/Linuxbrew after installation
        brew update && brew upgrade

        if [[ "$OS" != "macOS" ]]; then
            # Recommend installing GCC for non-macOS systems
            brew install gcc
        fi

    else
        echo "Failed to find Homebrew commands after installation."
        exit 1
    fi
}

# Function to install GitHub CLI (gh)
install_github_cli() {
    if command -v gh >/dev/null 2>&1; then
        echo "GitHub CLI is already installed. Version:" && gh --version
    else
        echo "Installing GitHub CLI..."
        if brew install gh; then
            echo "GitHub CLI installed successfully. Version:" && gh --version
        else
            echo "Failed to install GitHub CLI."
            exit 1
        fi
    fi
}

# Function to install Doppler CLI
install_doppler_cli() {
    if command -v doppler >/dev/null 2>&1; then
        echo "Doppler CLI is already installed."
        return
    fi
    if [[ "$OS" == "macOS" ]]; then
        # Install Doppler CLI using Homebrew
        echo "Installing Doppler CLI using Homebrew..."
        brew install doppler
    else
        # Install Doppler CLI using the install script
        echo "Installing Doppler CLI using the install script..."
        if (curl -Ls --tlsv1.2 --proto "=https" --retry 3 https://cli.doppler.com/install.sh || wget -t 3 -qO- https://cli.doppler.com/install.sh) | $SUDO sh; then
            echo "Doppler CLI installed successfully."
        else
            echo "Doppler CLI installation failed."
            exit 1
        fi
    fi
}

export -f detect_and_export_environment check_sudo_requirement install_update_system_common_packages install_and_update_homebrew install_github_cli install_doppler_cli

detect_and_export_environment
check_sudo_requirement
install_update_system_common_packages "$SYSTEM_PACKAGE_MANAGER" COMMON_PACKAGES[@] # Call the function to install common packages
install_and_update_homebrew
install_github_cli
install_doppler_cli

echo "Please run 'source ~/.bashrc' on Linux or 'source ~/.zshrc' on macOS to update your PATH."
