#!/bin/bash
# Function to source profile files
source_profiles() {
    local profile_files=("$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc")
    for profile_file in "${profile_files[@]}"; do
        if [ -f "$profile_file" ]; then
            # shellcheck disable=SC1090
            source "$profile_file"
        fi
    done
}

# Call the function to source profile files
source_profiles
