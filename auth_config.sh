#!/bin/bash
# Prevent storing sensitive commands in bash history
export HISTIGNORE='doppler*:gh auth*'

# Authenticate with GitHub using token authentication
authenticate_with_github() {
    # Copy the GITHUB_TOKEN to a different variable and unset the original
    local github_token=$GITHUB_TOKEN
    unset GITHUB_TOKEN

    echo "Checking GitHub authentication status..."
    # Redirect output to /dev/null, but preserve the exit status
    if gh auth status >/dev/null 2>&1; then
        echo "Already authenticated with GitHub."
    else
        echo "Authenticating with GitHub..."
        # Remove the debug line in production to avoid leaking the token
        echo "GITHUB_TOKEN is: $github_token"
        if [ -n "$github_token" ]; then
            echo "Using the provided GITHUB_TOKEN environment variable."
            if echo "$github_token" | gh auth login --with-token; then
                echo "GitHub authentication successful."
            else
                echo "GitHub authentication failed."
                exit 1
            fi
        else
            echo "No GITHUB_TOKEN provided. Prompting for token..."
            read -rp "Enter your GitHub token: " GITHUB_TOKEN
            if echo "$github_token" | gh auth login --with-token; then
                echo "GitHub authentication successful."
            else
                echo "GitHub authentication failed."
                exit 1
            fi
        fi
    fi
}

# Authenticate with Doppler using a Service Token
authenticate_with_doppler() {
    # Copy the DOPPLER_TOKEN, DOPPLER_PROJECT, and DOPPLER_CONFIG env vars to a different local variable and unset the original global env vars
    local doppler_token=$DOPPLER_TOKEN doppler_project=$DOPPLER_PROJECT doppler_config=$DOPPLER_CONFIG
    unset DOPPLER_TOKEN DOPPLER_PROJECT DOPPLER_CONFIG

    echo "Authenticating with Doppler..."
    # Prompt for token if not provided
    if [ -z "$doppler_token" ]; then
        read -rp "Enter your Doppler Service Token: " doppler_token
    fi
    # Prompt for project if not provided
    if [ -z "$doppler_project" ]; then
        read -rp "Enter your Doppler Project: " doppler_project
    fi
    # Prompt for config if not provided
    if [ -z "$doppler_config" ]; then
        read -rp "Enter your Doppler Config: " doppler_config
    fi

    # export DOPPLER_TOKEN
    doppler setup --no-interactive --no-read-env --token "$doppler_token" --project "$doppler_project" --config "$doppler_config"

    if [ $? -eq 0 ]; then
        echo "Doppler is configured for your project."
    else
        echo "Doppler setup failed."
    fi
}

# Call the authentication functions
authenticate_with_github
authenticate_with_doppler
