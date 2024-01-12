#!/bin/bash

# Function to append the system_prep, auth_config, and install functions to the shell config file.
append_to_shell_config() {
    local shell_config="$1"

    # Define a helper function to append a function if it's not already in the config
    append_function_to_config() {
        local function_name="$1"
        if ! grep -q "${function_name}()" "$shell_config"; then
            echo -e "\n# ${function_name} function for environment configuration" >>"$shell_config"
            declare -f "${function_name}" >>"$shell_config"
            echo "export -f ${function_name}" >>"$shell_config"
        fi
    }

    # Append system_prep function
    append_function_to_config system_prep

    # Append auth_config function
    append_function_to_config auth_config

    # Append install_bun function
    append_function_to_config install_bun

    # Append install_node function
    append_function_to_config install_node

    # Append install_python function
    append_function_to_config install_python

}

# Function to configure the shell environment by appending functions to the shell config files.
configure_shell() {
    local shell_updated=false

    # Helper function to append to config and source it
    update_shell_config() {
        local config_file="$1"
        local profile_file="$2"

        if [ -f "$config_file" ]; then
            append_to_shell_config "$config_file" && shell_updated=true
            # shellcheck disable=SC1090
            source "$config_file"
            # shellcheck disable=SC1090
            [ -f "$profile_file" ] && source "$profile_file"
        fi
    }

    # Update .bashrc and .bash_profile if they exist
    update_shell_config "$HOME/.bashrc" "$HOME/.bash_profile"

    # Update .zshrc and .zprofile if they exist
    update_shell_config "$HOME/.zshrc" "$HOME/.zprofile"

    # Inform the user that the shell configuration has been updated
    if [ "$shell_updated" = true ]; then
        echo "Shell configuration updated. Please restart your shell or source the appropriate config file to apply changes."
    else
        echo "No shell configuration files updated."
    fi
}
